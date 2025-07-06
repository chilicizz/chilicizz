import 'package:chilicizz/HKO/typhoon_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TyphoonHttpClientJson hkoTyphoonClient;
  group('TyphoonHttpClient', () {
    test('fetchTyphoonFeed returns a list of Typhoon on success', () async {
      hkoTyphoonClient = TyphoonHttpClientJson('http://localhost:8080');
      List<Typhoon> typhoons = await hkoTyphoonClient.fetchTyphoonFeed();
      expect(typhoons.isNotEmpty, true, reason: "Should load one typhoon");

      var typhoonTrack = await hkoTyphoonClient.fetchTyphoonTrack("${typhoons[0].id}");
      expect(typhoonTrack, isNotNull, reason: "Should load one typhoon");
    });
  }, skip: true);
}
