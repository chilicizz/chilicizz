import 'dart:async';

import 'package:flutter/material.dart';

import '../common.dart';
import 'dummy_typhoon.dart';
import 'hko_types.dart';
import 'hko_typhoon_tile.dart';

class HKOTyphoonTab extends StatefulWidget {
  const HKOTyphoonTab({Key? key}) : super(key: key);

  @override
  State<HKOTyphoonTab> createState() => _HKOTyphoonTabState();
}

class _HKOTyphoonTabState extends State<HKOTyphoonTab> {
  static const Duration tickInterval = Duration(minutes: 30);

  late Timer timer;
  late Future<List<Typhoon>> futureTyphoons;
  DateTime lastTick = DateTime.now();

  Future<List<Typhoon>> dummyTyphoonList() async {
    return [dummyTyphoon()];
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(tickInterval, (Timer t) => _tick(t: t));
    _tick();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _tick({Timer? t}) async {
    setState(() {
      futureTyphoons = fetchTyphoonFeed();
      lastTick = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _tick,
            child: buildLastTick(lastTick),
            onLongPress: () {
              setState(() {
                futureTyphoons = dummyTyphoonList();
              });
            },
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _tick,
          child: FutureBuilder(
            future: futureTyphoons,
            builder:
                (BuildContext context, AsyncSnapshot<List<Typhoon>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return loadingListView();
                default:
                  List<Typhoon> typhoons;
                  if (snapshot.hasError) {
                    return hasErrorListView(snapshot);
                  } else {
                    typhoons = snapshot.data ?? [];
                  }
                  return typhoons.isNotEmpty
                      ? ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: typhoons.length,
                          itemBuilder: (BuildContext context, int index) {
                            var typhoon = typhoons[index];
                            return TyphoonTile(
                              typhoon: typhoon,
                              lastTick: lastTick,
                            );
                          },
                        )
                      : buildNoCurrentTyphoons();
              }
            },
          ),
        ),
      ),
    );
  }

  ListView buildNoCurrentTyphoons() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.done),
          ),
          title: const Text("No active typhoon warnings"),
          subtitle: buildLastTick(lastTick),
        ),
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.done),
          ),
          title: const Text("No active typhoon warnings"),
          subtitle: buildLastTick(lastTick),
        )
      ],
    );
  }
}
