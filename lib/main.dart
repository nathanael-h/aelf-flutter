import 'package:aelf_flutter/app_screens/aelf_home_page.dart';
import 'package:aelf_flutter/utils/bibleDbProvider.dart';
import 'package:aelf_flutter/states/currentZoomState.dart';
import 'package:aelf_flutter/states/liturgyState.dart';
import 'package:aelf_flutter/states/pageState.dart';
import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/states/selectedCelebrationState.dart';
import 'package:aelf_flutter/states/biblePositionState.dart';
import 'package:aelf_flutter/utils/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:aelf_flutter/app_screens/bible_lists_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(MyApp());
  // Initialize FFI
  sqfliteFfiInit();
  // Change the default factory
  databaseFactory = databaseFactoryFfi;
  // Initialize database
  ensureDatabase();
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    // Prevent screen to be locked
    if (defaultTargetPlatform != TargetPlatform.linux) {
      WakelockPlus.enable();
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentZoom>(create: (_) => CurrentZoom()),
        ChangeNotifierProvider<LiturgyState>(create: (_) => LiturgyState()),
        ChangeNotifierProvider<PageState>(create: (_) => PageState()),
        ChangeNotifierProvider<FeatureFlagsState>(
            create: (_) => FeatureFlagsState()),
        ChangeNotifierProvider<SelectedCelebrationState>(
            create: (_) => SelectedCelebrationState()),
        ChangeNotifierProvider<BiblePositionState>(
            create: (_) => BiblePositionState())
      ],
      child: ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateRoute: (settings) {
              // If you push the PassArguments route
              if (settings.name == PassArgumentsScreen.routeName) {
                // Cast the arguments to the correct type: ScreenArguments.
                final ScreenArguments? args =
                    settings.arguments as ScreenArguments?;

                // Then, extract the required data from the arguments and
                // pass the data to the correct screen.
                return MaterialPageRoute(
                  builder: (context) {
                    return PassArgumentsScreen(
                      title: args!.title,
                      message: args.message,
                    );
                  },
                );
              }
              return null;
            },
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate
            ],
            supportedLocales: [
              const Locale('fr', 'FR'),
            ],
            // Use builder to inject the dynamic theme without rebuilding MaterialApp.
            // This prevents open overlays (popups, dialogs) from being dismissed
            // when the theme changes.
            builder: (context, child) {
              return Consumer<ThemeNotifier>(
                builder: (context, notifier, _) => Theme(
                  data: notifier.currentTheme,
                  child: child!,
                ),
              );
            },
            // Disable dynamic font size as it is now possible to pinch to zoom
            // source https://stackoverflow.com/a/54489680
            home: AelfHomePage()),
      ),
    );
  }
}

void ensureDatabase() async {
  await BibleDbSqfProvider.instance.ensureDatabase();
}
