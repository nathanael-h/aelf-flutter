// Runs `flutter test` with a readable console and an optional JUnit report.
//
// `flutter test` interleaves every `print`/`debugPrint` the app makes (API
// downloads, liturgy state logs…) with one progress line per test, which buries
// the failures. This wraps it with `--reporter json` and:
//
//   - prints nothing for passing tests, and for each failure its error, stack
//     and the output captured while *that* test ran;
//   - ends with a per-file summary and the commands to rerun what failed;
//   - with --junit, writes a JUnit XML report (GitLab's unit test reports:
//     the pipeline Tests tab and the merge request Test summary). Each test
//     case carries its captured output as <system-out>.
//
// Anything flutter prints that is not a JSON event (build output, compile
// errors) is passed through unchanged. The exit code is flutter's.
//
// Usage:
//   dart tool/test_runner.dart [--junit <file.xml>] [--verbose] [-- <flutter test args>]
//
//   dart tool/test_runner.dart                                  # test/, like `flutter test`
//   dart tool/test_runner.dart --junit build/test-results/unit.xml -- --coverage
//   dart tool/test_runner.dart -- integration_test/app_launch_test.dart -d linux
//
// --verbose also echoes every captured print as it happens.
//
// Environment:
//   FLUTTER  command used to invoke Flutter (default: flutter; set to
//            "fvm flutter" when using FVM)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const _usage =
    'Usage: dart tool/test_runner.dart [--junit <file.xml>] [--verbose] '
    '[-- <flutter test args>]';

Future<void> main(List<String> arguments) async {
  String? junitPath;
  var verbose = false;
  final flutterArgs = <String>[];

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--') {
      flutterArgs.addAll(arguments.skip(i + 1));
      break;
    } else if (arg == '--junit' && i + 1 < arguments.length) {
      junitPath = arguments[++i];
    } else if (arg.startsWith('--junit=')) {
      junitPath = arg.substring('--junit='.length);
    } else if (arg == '--verbose' || arg == '-v') {
      verbose = true;
    } else if (arg == '--help' || arg == '-h') {
      stdout.writeln(_usage);
      return;
    } else {
      stderr.writeln('Unknown argument: $arg\n$_usage');
      exit(64);
    }
  }

  final flutter = (Platform.environment['FLUTTER'] ?? 'flutter')
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();
  final run = _Run(verbose: verbose);

  final process = await Process.start(
    flutter.first,
    [...flutter.skip(1), 'test', '--reporter', 'json', ...flutterArgs],
    runInShell: Platform.isWindows,
  );

  final stdoutDone = process.stdout
      .transform(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter())
      .listen(run.onLine)
      .asFuture<void>();
  final stderrDone = process.stderr.pipe(stderr);

  var exitCode = await process.exitCode;
  await stdoutDone;
  await stderrDone.catchError((_) {});

  run.printSummary();
  if (junitPath != null) {
    final file = File(junitPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(run.toJUnit());
    stdout.writeln('JUnit report: ${file.path}');
  }

  // flutter can exit 0 without running anything useful if it was killed
  // mid-run; never report that as a pass.
  if (exitCode == 0 && (!run.finished || run.failed.isNotEmpty)) exitCode = 1;
  exit(exitCode);
}

class _Test {
  _Test(this.id, this.name, this.suite, this.line, this.startMs,
      {required this.isLoader, this.skipReason});

  final int id;
  final String name;
  final _Suite suite;
  final int? line;
  final int startMs;
  final bool isLoader;
  String? skipReason;

  final output = StringBuffer();
  final errors = <({String message, String stack, bool isFailure})>[];
  String? result; // success | failure | error
  bool hidden = false;
  bool skipped = false;
  int endMs = 0;

  bool get done => result != null;
  bool get passed => result == 'success' && errors.isEmpty;

  /// Loader and setUpAll/tearDownAll entries are bookkeeping, only worth
  /// reporting when they fail.
  bool get reportable => passed ? !(isLoader || hidden) : true;

  /// flutter_test reports a failed `expect` in a widget test as an error and
  /// prints the TestFailure itself; count those as failures, not crashes.
  bool get isAssertionFailure =>
      result == 'failure' ||
      errors.any((e) => e.isFailure) ||
      output.toString().contains(_testFailureHeader);

  /// One line saying what went wrong, for the JUnit message attribute.
  String get message {
    final lines = output.toString().split('\n');
    final thrown = lines.indexWhere((l) => l.startsWith('The following '));
    if (thrown != -1) {
      return lines
          .skip(thrown + 1)
          .takeWhile((l) => l.trim().isNotEmpty)
          .take(2)
          .map((l) => l.trim())
          .join(' ');
    }
    return errors.isEmpty ? result! : errors.first.message.split('\n').first;
  }

  String get details => errors
      .map((e) => '${e.message.trimRight()}\n${e.stack.trimRight()}')
      .join('\n\n');

  double get seconds => (endMs - startMs) / 1000;
  String get location => line == null ? suite.path : '${suite.path}:$line';
}

class _Suite {
  _Suite(this.path);

  final String path;
  final tests = <_Test>[];
}

class _Run {
  _Run({required this.verbose});

  final bool verbose;
  final _suites = <int, _Suite>{};
  final _tests = <int, _Test>{};
  final failed = <_Test>[];
  final _cwd = Directory.current.path;
  final _live = stdout.hasTerminal;
  bool finished = false;
  int _totalMs = 0;
  int _passed = 0;
  int _skipped = 0;

  void onLine(String line) {
    Map<String, dynamic>? event;
    if (line.startsWith('{')) {
      try {
        final decoded = jsonDecode(line);
        if (decoded is Map<String, dynamic> && decoded['type'] is String) {
          event = decoded;
        }
      } on FormatException {
        // Not an event after all: fall through and echo it.
      }
    }
    if (event == null) {
      _write(line);
      return;
    }
    _onEvent(event);
  }

  void _onEvent(Map<String, dynamic> event) {
    final time = (event['time'] as num?)?.toInt() ?? 0;
    switch (event['type']) {
      case 'suite':
        final suite = event['suite'] as Map<String, dynamic>;
        _suites[suite['id'] as int] =
            _Suite(_relative(suite['path'] as String? ?? '?'));
      case 'testStart':
        final t = event['test'] as Map<String, dynamic>;
        final suite = _suites[t['suiteID']] ?? _Suite('?');
        final metadata = t['metadata'] as Map<String, dynamic>? ?? const {};
        final name = t['name'] as String;
        final test = _Test(
          t['id'] as int,
          name,
          suite,
          // root_line is the line in the test file when the test is declared
          // through a helper living in another file.
          (t['root_line'] ?? t['line']) as int?,
          time,
          isLoader:
              (t['groupIDs'] as List).isEmpty && name.startsWith('loading '),
          skipReason: metadata['skipReason'] as String?,
        );
        _tests[test.id] = test;
        suite.tests.add(test);
      case 'print':
        final test = _tests[event['testID']];
        final message = event['message'] as String;
        test?.output.writeln(message);
        if (verbose) _write(message);
      case 'error':
        final test = _tests[event['testID']];
        if (test == null) return;
        test.errors.add((
          message: event['error'] as String? ?? '',
          stack: event['stackTrace'] as String? ?? '',
          isFailure: event['isFailure'] as bool? ?? false,
        ));
        // An error reported after the test completed still fails it.
        if (test.done && test.result == 'success' && test.errors.length == 1) {
          if (!test.isLoader && !test.hidden) {
            test.skipped ? _skipped-- : _passed--;
          }
          test.result = 'error';
          _onFailure(test);
        }
      case 'testDone':
        final test = _tests[event['testID']];
        if (test == null) return;
        test
          ..result = event['result'] as String
          ..hidden = event['hidden'] as bool? ?? false
          ..skipped = event['skipped'] as bool? ?? false
          ..endMs = time;
        if (!test.passed) {
          _onFailure(test);
        } else if (test.reportable) {
          test.skipped ? _skipped++ : _passed++;
        }
        _progress();
      case 'done':
        finished = true;
        _totalMs = time;
    }
  }

  void _onFailure(_Test test) {
    failed.add(test);
    final buffer = StringBuffer()
      ..writeln()
      ..writeln('✗ ${test.name}')
      ..writeln('  ${test.location}');
    // Output first: flutter_test dumps the actual exception there and its
    // error event only says "See exception logs above".
    final output = test.output.toString().trimRight();
    if (output.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('  --- output captured during this test ---')
        ..writeln(_indent(output))
        ..writeln('  ---');
    }
    buffer
      ..writeln()
      ..writeln(_indent(test.details));
    _write(buffer.toString());
  }

  void _progress() {
    if (!_live) return;
    stdout.write('\r\x1B[2K  $_passed passed, ${failed.length} failed, '
        '$_skipped skipped');
  }

  void _write(String text) {
    if (_live) stdout.write('\r\x1B[2K');
    stdout.writeln(text);
    _progress();
  }

  void printSummary() {
    if (_live) stdout.write('\r\x1B[2K');
    final out = StringBuffer()..writeln();

    final suites = _suites.values.toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final suite in suites) {
      final tests = suite.tests.where((t) => t.reportable);
      final failures = tests.where((t) => !t.passed).length;
      final count = tests.where((t) => !t.isLoader && !t.hidden).length;
      out.writeln(failures == 0
          ? '✓ ${suite.path} ($count)'
          : '✗ ${suite.path} ($failures of $count failed)');
    }

    final total = _passed + failed.length + _skipped;
    final seconds = (_totalMs / 1000).toStringAsFixed(1);
    out
      ..writeln()
      ..writeln('$total tests: $_passed passed, ${failed.length} failed, '
          '$_skipped skipped in ${seconds}s');
    if (!finished) out.writeln('The test run did not complete.');

    if (failed.isNotEmpty) {
      out
        ..writeln()
        ..writeln('Rerun the failures:');
      for (final test in failed) {
        out.writeln(test.isLoader || test.hidden
            ? '  flutter test ${test.suite.path}'
            : '  flutter test ${test.suite.path} '
                '--plain-name ${_shellQuote(test.name)}');
      }
    }
    stdout.write(out);
  }

  String toJUnit() {
    final xml = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<testsuites time="${_totalMs / 1000}">');
    for (final suite in _suites.values) {
      final tests = suite.tests.where((t) => t.done && t.reportable).toList();
      if (tests.isEmpty) continue;
      final failures = tests.where((t) => !t.passed && t.isAssertionFailure);
      final errors = tests.where((t) => !t.passed && !t.isAssertionFailure);
      final time = tests.fold<double>(0, (sum, t) => sum + t.seconds);
      xml.writeln('  <testsuite name="${_attr(suite.path)}" '
          'tests="${tests.length}" failures="${failures.length}" '
          'errors="${errors.length}" '
          'skipped="${tests.where((t) => t.skipped).length}" time="$time">');
      for (final test in tests) {
        xml.write('    <testcase classname="${_attr(suite.path)}" '
            'name="${_attr(test.name)}" file="${_attr(suite.path)}" '
            'time="${test.seconds}">');
        if (test.skipped) {
          xml.write('<skipped message="${_attr(test.skipReason ?? '')}"/>');
        }
        if (!test.passed) {
          final tag = test.isAssertionFailure ? 'failure' : 'error';
          final output = test.output.toString().trimRight();
          xml.write('<$tag message="${_attr(test.message)}">'
              '${_text('${test.location}\n\n$output\n\n${test.details}')}'
              '</$tag>');
        }
        final output = test.output.toString();
        if (output.isNotEmpty) {
          xml.write('<system-out>${_text(output)}</system-out>');
        }
        xml.writeln('</testcase>');
      }
      xml.writeln('  </testsuite>');
    }
    xml.writeln('</testsuites>');
    return xml.toString();
  }

  String _relative(String path) {
    final prefix = '$_cwd${Platform.pathSeparator}';
    return path.startsWith(prefix) ? path.substring(prefix.length) : path;
  }
}

const _testFailureHeader = 'The following TestFailure was thrown';

String _indent(String text) =>
    text.split('\n').map((l) => l.isEmpty ? l : '  $l').join('\n');

String _shellQuote(String s) => "'${s.replaceAll("'", r"'\''")}'";

// ANSI colour codes and the control characters XML 1.0 forbids.
final _unprintable =
    RegExp(r'\x1B\[[0-9;]*[A-Za-z]|[\x00-\x08\x0B\x0C\x0E-\x1F]');

String _text(String s) => s
    .replaceAll(_unprintable, '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _attr(String s) => _text(s)
    .replaceAll('"', '&quot;')
    .replaceAll('\n', '&#10;')
    .replaceAll('\r', '&#13;')
    .replaceAll('\t', '&#9;');
