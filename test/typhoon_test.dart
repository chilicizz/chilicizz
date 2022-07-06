// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:chilicizz/HKO/hko_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Typhoon unit tests', () {
    test('testParseTyphoonData', () async {
      String fileContents =
          await File('test/resources/typhoonExample.xml').readAsString();
      expect(fileContents.isNotEmpty, true,
          reason: "Test file should not be empty");
      List<Typhoon> typhoons = parseTyphoonFeed(fileContents);
      expect(typhoons.isNotEmpty, true, reason: "Should load one typhoon");
      expect(typhoons[0].id, 2102, reason: "ID was not parsed correctly");
      expect(typhoons[0].englishName, 'SURIGAE',
          reason: "Name not parsed correctly");
      expect(typhoons[0].chineseName, '舒力基',
          reason: "Chinese name not parsed correctly");
      expect(typhoons[0].url.trim(),
          'https://www.weather.gov.hk/wxinfo/currwx/hko_tctrack_2102.xml',
          reason: "URL Not parsed correctly");
    });

    test('testParseTyphoonTrack', () async {
      String fileContents =
          await File('test/resources/typhoonTrackExample.xml').readAsString();
      expect(fileContents.isNotEmpty, true,
          reason: "Test file should not be empty");
      TyphoonTrack? typhoonTrack = parseTyphoonTrack(fileContents);
      expect(typhoonTrack != null, true, reason: "Should load track data");
      expect(typhoonTrack?.bulletin != null, true,
          reason: "Should load track bulletin data");
      expect(typhoonTrack?.current != null, true,
          reason: "Should load current status");
      expect(typhoonTrack?.past != null && typhoonTrack!.past.isNotEmpty, true,
          reason: "Should load past status");
    });

    test('testParseTyphoonTrack2', () async {
      String fileContents =
          await File('test/resources/typhoonTrackExample2.xml').readAsString();
      expect(fileContents.isNotEmpty, true,
          reason: "Test file should not be empty");
      TyphoonTrack? typhoonTrack = parseTyphoonTrack(fileContents);
      expect(typhoonTrack != null, true, reason: "Should load track data");
      expect(typhoonTrack?.bulletin != null, true,
          reason: "Should load track bulletin data");
      expect(typhoonTrack?.current != null, true,
          reason: "Should load current status");
      expect(typhoonTrack?.past != null && typhoonTrack!.past.isNotEmpty, true,
          reason: "Should load past status");
    });

    /*
    test('testFetchTyphoon', () async {
      List<Typhoon> fileContents = await fetchTyphoonFeed();
      expect(fileContents.isNotEmpty, true,
          reason: "Test file should not be empty");
    });
     */
  });
}
