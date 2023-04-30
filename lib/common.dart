import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';

class NavRoute {
  String path;
  List<NavRoute> subRoutes;
  String label;
  Widget Function(BuildContext) buildFunction;

  NavRoute(
      {required this.path,
      required this.label,
      required this.buildFunction,
      this.subRoutes = const []});

  Map<String, Widget Function(BuildContext)> getRoutes() {
    var routes = {path: buildFunction};
    if (subRoutes.isNotEmpty) {
      routes
          .addAll({for (var e in subRoutes) "$path${e.path}": e.buildFunction});
    }
    return routes;
  }
}

class NavDrawer extends StatelessWidget {
  final List<NavRoute> routes;

  const NavDrawer({
    Key? key,
    required this.routes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Center(
              child: Column(
                children: const <Widget>[
                  Padding(
                    padding: EdgeInsets.all(5.0),
                    child: SizedBox(
                        height: 60,
                        child: Image(
                            fit: BoxFit.fill,
                            image: AssetImage('assets/cn.png'))),
                  ),
                  Text(
                    'ChiliCizz',
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  Text('a demo app made by\nCyril Ng Lung Kit 2022'),
                ],
              ),
            ),
          ),
          for (var route in routes)
            route.subRoutes.isEmpty
                ? ListTile(
                    title: Text(route.label),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                          context, route.path, ModalRoute.withName('/'));
                    },
                  )
                : ExpansionTile(
                    initiallyExpanded: !isSmallDevice(),
                    title: GestureDetector(
                      onTap: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, route.path, ModalRoute.withName('/'));
                      },
                      child: Text(route.label),
                    ),
                    children: [
                      for (var subRoute in route.subRoutes)
                        ListTile(
                          title: Text(subRoute.label),
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                                context,
                                "${route.path}${subRoute.path}",
                                ModalRoute.withName('/'));
                          },
                        )
                    ],
                  )
        ],
      ),
    );
  }
}

String simpleDateFormat(DateTime? datetime) {
  if (datetime != null) {
    return formatDate(datetime.toLocal(), [D, " ", dd, ", ", H, ":", nn]);
  } else {
    return "";
  }
}

String shortDateFormat(DateTime? dateTime) {
  if (dateTime != null) {
    return formatDate(
      dateTime.toLocal(),
      [
        D,
        " ",
        dd,
        " ",
        M,
        ", ",
        H,
        ":",
        nn,
      ],
    );
  } else {
    return "";
  }
}

String mapLabelFormat(DateTime? dateTime) {
  if (dateTime != null) {
    return formatDate(
      dateTime.toLocal(),
      [
        H,
        'h ',
        d,
        "/",
        m,
      ],
    );
  } else {
    return "";
  }
}

Text buildLastUpdatedText(DateTime? lastUpdateTime) {
  if (lastUpdateTime != null) {
    return Text("last updated ${shortDateFormat(lastUpdateTime.toLocal())}");
  } else {
    return const Text("");
  }
}

Text buildLastTick(DateTime lastTickTime) {
  return Text("last refresh ${shortDateFormat(lastTickTime.toLocal())}");
}

Text buildIssued(DateTime lastTickTime) {
  return Text("issued ${shortDateFormat(lastTickTime.toLocal())}");
}

bool isSmallScreen(BuildContext context) {
  // The equivalent of the "smallestWidth" qualifier on Android.
  var shortestSide = MediaQuery.of(context).size.shortestSide;
  // Determine if we should use mobile layout or not, 600 here is
  // a common breakpoint for a typical 7-inch tablet.
  final bool useMobileLayout = shortestSide < 600;
  return useMobileLayout;
}

bool isSmallDevice() {
  final data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
  return data.size.shortestSide < 600;
}

ListView loadingListView() {
  return ListView(
    children: const [
      ListTile(
        leading: CircularProgressIndicator(),
        title: Text("Loading..."),
      ),
    ],
  );
}

ListView hasErrorListView(AsyncSnapshot snapshot) {
  return ListView(
    children: [
      ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.error),
        ),
        title: const Text("Error loading data"),
        subtitle: Text("${snapshot.error}"),
      ),
    ],
  );
}