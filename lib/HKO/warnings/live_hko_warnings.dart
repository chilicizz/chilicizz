import 'package:chilicizz/data/hko_warnings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common.dart';
import '../warnings_model.dart';
import './hko_warnings_list.dart';

// This page displays live HKO warnings
class LiveHKOWarnings extends StatefulWidget {
  const LiveHKOWarnings({super.key});

  @override
  State<LiveHKOWarnings> createState() => _LiveHKOWarningsState();
}

class _LiveHKOWarningsState extends State<LiveHKOWarnings> {
  bool _displayDummy = false;

  @override
  Widget build(BuildContext context) {
    if (_displayDummy) {
      return Scaffold(
        body: Center(
          child: HKOWarningsList(warnings: dummyWarnings()),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _displayDummy = false;
            });
          },
          child: const Icon(Icons.navigate_before),
        ),
      );
    }

    var provider = context.watch<HKOWarningsProvider>();
    return Scaffold(
      floatingActionButton: GestureDetector(
        child: ElevatedButton(
          onPressed: () {
            provider.triggerRefresh();
          },
          child: buildLastTick(provider.lastTick),
        ),
        onLongPress: () async {
          setState(() {
            _displayDummy = true;
          });
        },
      ),
      body: RefreshIndicator(
        onRefresh: () {
          provider.triggerRefresh();
          return Future.value();
        },
        child: Center(
          child: ValueListenableBuilder<List<WarningInformation>?>(
            valueListenable: provider.hkoWeatherWarnings,
            builder: (context, warnings, child) {
              if (warnings == null) {
                provider.triggerRefresh();
                return LoadingListView();
              } else if (warnings.isEmpty) {
                return NoWarningsList(lastTick: provider.lastTick);
              } else {
                return HKOWarningsList(warnings: warnings);
              }
            },
          ),
        ),
      ),
    );
  }
}
