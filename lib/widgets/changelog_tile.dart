import 'package:flutter/material.dart';
import 'package:aelf_flutter/models/changelog_entry.dart';

class ChangelogTile extends StatelessWidget {
  final ChangelogEntry entry;

  const ChangelogTile({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        "Version ${entry.version} - ${entry.date}",
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
      ),
      subtitle: Text(
        entry.description,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
      ),
    );
  }
}
