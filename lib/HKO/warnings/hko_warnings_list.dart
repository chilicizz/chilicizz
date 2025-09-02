import 'package:flutter/material.dart';

import '../../common.dart';
import '../warnings_model.dart';

/// A widget that displays a list of weather warnings.
class HKOWarningsListView extends StatelessWidget {
  const HKOWarningsListView({
    super.key,
    required this.warnings,
  });

  final List<WarningInformation> warnings;

  @override
  Widget build(BuildContext context) {
    bool initiallyExpanded = !isSmallScreen(context) || warnings.length == 1;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: warnings.length,
      itemBuilder: (BuildContext context, int index) {
        return WarningExpansionTile(warning: warnings[index], initiallyExpanded: initiallyExpanded);
      },
    );
  }
}

class WarningExpansionTile extends StatelessWidget {
  final WarningInformation warning;
  final bool initiallyExpanded;

  const WarningExpansionTile({
    super.key,
    required this.warning,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: warning.getCircleAvatar(),
      title: Text(
        warning.getDescription(),
        // style: Theme.of(context).textTheme.headlineSmall,
      ),
      subtitle: buildIssued(warning.updateTime),
      initiallyExpanded: initiallyExpanded,
      children: [
        for (var s in warning.contents)
          ListTile(
            title: Text(s),
          )
      ],
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
        NoWarningsTile(lastTick: lastTick),
      ],
    );
  }
}

class NoWarningsTile extends StatelessWidget {
  const NoWarningsTile({
    super.key,
    required this.lastTick,
  });

  final DateTime lastTick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.done),
      ),
      title: const Text("No weather warnings in force"),
      subtitle: buildLastTick(lastTick),
    );
  }
}
