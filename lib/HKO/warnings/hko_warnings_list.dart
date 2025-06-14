import 'package:flutter/material.dart';

import '../../common.dart';
import '../hko_types.dart';

class HKOWarningsList extends StatelessWidget {
  const HKOWarningsList({
    super.key,
    required this.warnings,
  });

  final List<WarningInformation> warnings;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: warnings.length,
      itemBuilder: (BuildContext context, int index) {
        var warning = warnings[index];
        CircleAvatar icon = warning.getCircleAvatar();
        return ExpansionTile(
          leading: icon,
          title: Text(warning.getDescription()),
          subtitle: buildIssued(warning.updateTime),
          initiallyExpanded: !isSmallScreen(context) || warnings.length == 1,
          children: [
            for (var s in warning.contents)
              ListTile(
                title: Text(s),
              )
          ],
        );
      },
    );
  }
}

class NoWarningsList extends StatelessWidget {
  const NoWarningsList({
    super.key,
    required this.lastTick,
  });

  final DateTime lastTick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.done),
          ),
          title: const Text("No weather warnings in force"),
          subtitle: buildLastTick(lastTick),
        ),
      ],
    );
  }
}
