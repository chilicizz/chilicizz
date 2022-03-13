import 'dart:async';

import 'package:flutter/material.dart';

import 'common.dart';
import 'hko_types.dart';

class HKOTyphoonTab extends StatefulWidget {
  const HKOTyphoonTab({Key? key}) : super(key: key);

  @override
  State<HKOTyphoonTab> createState() => _HKOTyphoonTabState();
}

class _HKOTyphoonTabState extends State<HKOTyphoonTab> {
  static const Duration tickInterval = Duration(minutes: 10);

  late Timer timer;
  late List<Typhoon> typhoons;

  DateTime lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    typhoons = [];
    timer = Timer.periodic(tickInterval, (Timer t) => _tick(t: t));
    _tick();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _tick({Timer? t}) async {
    try {
      var fetchedTyphoons = await fetchTyphoonFeed();
      lastTick = DateTime.now();
      setState(() {
        typhoons = fetchedTyphoons;
      });
    } catch (e) {
      lastTick = DateTime.now();
      setState(() {
        typhoons = [
          Typhoon(
              id: -1,
              chineseName: '$e',
              englishName: "Failed to fetch typhoon data",
              url: "")
        ];
      });
    }
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
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _tick,
          child: typhoons.isNotEmpty
              ? ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: typhoons.length,
                  itemBuilder: (BuildContext context, int index) {
                    var typhoon = typhoons[index];
                    CircleAvatar icon =
                        const CircleAvatar(child: Icon(Icons.storm));
                    return ExpansionTile(
                      leading: icon,
                      title: Text(typhoon.englishName),
                      subtitle: Text(typhoon.chineseName),
                      initiallyExpanded: !isSmallDevice(),
                      children: [
                        Text(typhoon.url),
                      ],
                    );
                  },
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ListTile(
                      title: const Text("No current typhoon warnings"),
                      subtitle: buildLastTick(lastTick),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
