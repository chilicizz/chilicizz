import 'package:chilicizz/data/aqi_provider.dart';
import 'package:chilicizz/Chat/chat.dart';
import 'package:chilicizz/data/chat_provider.dart';
import 'package:chilicizz/HKO/typhoon/hko_typhoon_tab.dart';
import 'package:chilicizz/data/hko_warnings_provider.dart';
import 'package:chilicizz/HKO/warnings/live_hko_warnings.dart';
import 'package:chilicizz/config/config_controller.dart';
import 'package:chilicizz/rss_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'AQI/live_aqi_tab.dart';
import 'common.dart';

const String appEnv = String.fromEnvironment('ENV', defaultValue: "pdn");

final List<NavRoute> routes = [
  NavRoute(
      path: '/dashboard',
      label: "Dashboard",
      buildFunction: (context) => const Dashboard(),
      subRoutes: [
        NavRoute(
          path: '/hko',
          label: "HKO Warnings",
          buildFunction: (context) => const Dashboard(initial: 0),
        ),
        NavRoute(
          path: '/aqi',
          label: "Air Quality",
          buildFunction: (context) => const Dashboard(initial: 1),
        ),
        NavRoute(
          path: '/typhoon',
          label: "HKO Typhoon",
          buildFunction: (context) => const Dashboard(initial: 2),
        ),
      ]),
  NavRoute(
    path: '/chat',
    label: "🚧 Chat",
    buildFunction: (context) => const ChatScreen(title: "Chat"),
  ),
  NavRoute(
    path: '/rss',
    label: "🚧 RSS Reader",
    buildFunction: (context) => const RSSReader(),
  ),
];

Future<void> main() async {
  await dotenv.load(fileName: "assets/config/$appEnv.properties");
  debugPrint("Starting environment: $appEnv");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, Widget Function(BuildContext)> appRoutes = {};
    for (var route in routes) {
      appRoutes.addAll(route.getRoutes());
    }
    return MultiProvider(
      providers: [
        Provider(create: (context) => ConfigController()),
        Provider(create: (context) => ChatProvider(Uri.parse(dotenv.env['chatUrl']!))),
        Provider(
          create: (context) => HKOWarningsProvider(Uri.parse(dotenv.env['warningsUrl']!),
              dotenv.env['hkoTyphoonUrl']!, dotenv.env['hkoTyphoonBase']!),
        ),
        Provider(
          create: (context) => AQIProvider(Uri.parse(dotenv.env['aqiUrl']!)),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'app.cyrilng.com',
            theme: ThemeData(
                colorScheme: ColorScheme.fromSwatch(
                    primarySwatch: Colors.deepPurple, brightness: Brightness.light),
                useMaterial3: true),
            initialRoute: '/dashboard',
            routes: appRoutes,
          );
        },
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  final int initial;

  const Dashboard({super.key, this.initial = 0});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initial,
      length: 3,
      child: Scaffold(
        drawer: NavDrawer(routes: routes),
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Text("WARNINGS")),
              Tab(icon: Text("AIR QUALITY")),
              Tab(icon: Text("TYPHOON")),
              // Tab(icon: Text("🚧")),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  final qrController = TextEditingController();
                  qrController.text = 'https://app.cyrilng.com/';
                  final ValueNotifier<String> textValue = ValueNotifier<String>(qrController.text);
                  return AlertDialog(
                    title: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.center,
                      controller: qrController,
                      onChanged: (value) => {textValue.value = value},
                    ),
                    content: ValueListenableBuilder(
                      valueListenable: textValue,
                      builder: (BuildContext context, String value, Widget? child) {
                        return SizedBox(
                          height: 300,
                          width: 300,
                          child: QrImageView(
                            data: qrController.value.text,
                            version: QrVersions.auto,
                            embeddedImage: const AssetImage('assets/cn.png'),
                          ),
                        );
                      },
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Close'),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              ),
            )
          ],
        ),
        body: const TabBarView(
          children: [
            LiveHKOWarnings(),
            AQITabLoader(),
            TyphoonTab(),
          ],
        ),
      ),
    );
  }
}
