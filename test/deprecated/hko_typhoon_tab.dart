import 'dart:async';

import 'package:chilicizz/HKO/typhoon/dummy_typhoon.dart';
import 'package:chilicizz/HKO/typhoon_model.dart';
import 'package:chilicizz/data/hko_warnings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../lib/common.dart';
import '../../lib/HKO/typhoon/hko_typhoon_tile.dart';

@Deprecated("Using the unified hko_tab instead")
class TyphoonTab extends StatelessWidget {
  const TyphoonTab({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<HKOWarningsProvider>();
    return ValueListenableBuilder(
      valueListenable: provider.hkoTyphoons,
      builder: (BuildContext context, List<Typhoon>? typhoons, Widget? child) {
        if (typhoons == null) {
          provider.refreshTyphoons();
        }
        return Scaffold(
          body: Center(
            child: RefreshIndicator(
              onRefresh: () {
                provider.refreshTyphoons();
                return Future.value();
              },
              child: typhoons == null
                  ? const LoadingListView()
                  : typhoons.isNotEmpty
                      ? TyphoonsListView(typhoons: typhoons, lastTick: DateTime.now())
                      : NoTyphoonsListView(lastTick: DateTime.now()),
            ),
          ),
          floatingActionButton: GestureDetector(
            child: ElevatedButton(
              onPressed: () {
                provider.refreshTyphoons();
              },
              child: buildLastTick(DateTime.now()),
            ),
            onLongPress: () async {
              // For testing purposes, load dummy typhoon data
              final dummyTyphoons = await TyphoonHttpClientJson.dummyTyphoonList();
              provider.hkoTyphoons.value = dummyTyphoons;
              dummyTrack().then((track) {
                provider.typhoonTracks.addTyphoonTrack("2102", track);
              });
            },
          ),
        );
      },
    );
  }
}

class TyphoonsListView extends StatelessWidget {
  const TyphoonsListView({
    super.key,
    required this.typhoons,
    required this.lastTick,
  });

  final List<Typhoon> typhoons;
  final DateTime lastTick;

  @override
  Widget build(BuildContext context) {
    bool initiallyExpanded = typhoons.length == 1;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: typhoons.length,
      itemBuilder: (BuildContext context, int index) {
        return TyphoonListTile(
          typhoon: typhoons[index],
          lastTick: lastTick,
          initiallyExpanded: initiallyExpanded,
        );
      },
    );
  }
}

class NoTyphoonsListView extends StatelessWidget {
  const NoTyphoonsListView({
    super.key,
    required this.lastTick,
  });

  final DateTime lastTick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        NoTyphoonsTile(lastTick: lastTick),
      ],
    );
  }
}
