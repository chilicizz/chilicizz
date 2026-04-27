import 'package:chilicizz/HKO/typhoon/hko_typhoon_tile.dart';
import 'package:chilicizz/HKO/typhoon_model.dart';
import 'package:chilicizz/HKO/warnings/hko_warnings_list.dart';
import 'package:chilicizz/HKO/warnings_model.dart';
import 'package:chilicizz/common.dart';
import 'package:chilicizz/data/hko_warnings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Display HKO warnings in a unified tab
// This tab combines both live warnings and typhoon warnings into a single view
class UnifiedHkoTab extends StatefulWidget {
  const UnifiedHkoTab({super.key});

  @override
  State<UnifiedHkoTab> createState() => _UnifiedHkoTabState();
}

class _UnifiedHkoTabState extends State<UnifiedHkoTab> {
  bool _hasTriggeredInitialRefresh = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasTriggeredInitialRefresh) {
      var provider = context.read<HKOWarningsProvider>();
      if (provider.hkoWeatherWarnings.value == null || provider.hkoTyphoons.value == null) {
        provider.triggerRefresh();
        _hasTriggeredInitialRefresh = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<HKOWarningsProvider>();

    return Scaffold(
      floatingActionButton: GestureDetector(
        child: ElevatedButton(
          onPressed: () {
            provider.triggerRefresh();
          },
          child: buildLastTick(provider.lastTick),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          provider.triggerRefresh();
          return Future.value();
        },
        child: Center(
          child: ListenableBuilder(
            listenable: Listenable.merge([provider.hkoWeatherWarnings, provider.hkoTyphoons]),
            builder: (context, child) {
              List<WarningInformation>? warnings = provider.hkoWeatherWarnings.value;
              List<Typhoon>? typhoons = provider.hkoTyphoons.value;
              // Display loading or data based on current state
              if (warnings == null || typhoons == null) {
                return LoadingListView();
              } else if (typhoons.isEmpty && warnings.isEmpty) {
                return ListView(
                  children: [
                    NoWarningsTile(lastTick: provider.lastTick),
                    NoTyphoonsTile(lastTick: provider.lastTick),
                  ],
                );
              } else {
                bool initiallyExpanded = warnings.length + typhoons.length == 1;
                List<Widget> tiles = [];
                if (warnings.isEmpty) {
                  tiles.add(NoWarningsTile(lastTick: provider.lastTick));
                } else {
                  tiles.addAll(warnings.map(
                    (e) {
                      return WarningExpansionTile(
                        warning: e,
                        initiallyExpanded: initiallyExpanded,
                      );
                    },
                  ).toList());
                }
                if (typhoons.isEmpty) {
                  tiles.add(NoTyphoonsTile(lastTick: provider.lastTick));
                } else {
                  tiles.addAll(
                    typhoons.map(
                      (typhoon) {
                        return TyphoonListTile(
                          typhoon: typhoon,
                          lastTick: provider.lastTick,
                          initiallyExpanded: initiallyExpanded,
                        );
                      },
                    ).toList(),
                  );
                }
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: tiles,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
