// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:adaptive_navigation/adaptive_navigation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() => runApp(App());

/// The main app.
class App extends StatelessWidget {
  /// Creates an [App].
  App({Key? key}) : super(key: key);

  /// The title of the app.
  static const String title = 'GoRouter Example: Shared Scaffold';

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        title: title,
      );

  late final GoRouter _router = GoRouter(
    debugLogDiagnostics: true,
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            _build(const Page1View()),
      ),
      GoRoute(
        path: '/page2',
        builder: (BuildContext context, GoRouterState state) =>
            _build(const Page2View()),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) =>
        _build(ErrorView(state.error!)),

    // use the navigatorBuilder to keep the SharedScaffold from being animated
    // as new pages as shown; wrappiong that in single-page Navigator at the
    // root provides an Overlay needed for the adaptive navigation scaffold and
    // a root Navigator to show the About box
    navigatorBuilder:
        (BuildContext context, GoRouterState state, Widget child) => Navigator(
      onPopPage: (Route<dynamic> route, dynamic result) {
        route.didPop(result);
        return false; // don't pop the single page on the root navigator
      },
      pages: <Page<dynamic>>[
        MaterialPage<void>(
          child: state.error != null
              ? ErrorScaffold(body: child)
              : SharedScaffold(
                  selectedIndex: state.subloc == '/' ? 0 : 1,
                  body: child,
                ),
        ),
      ],
    ),
  );

  // wrap the view widgets in a Scaffold to get the exit animation just right on
  // the page being replaced
  Widget _build(Widget child) => Scaffold(body: child);
}

/// A scaffold with multiple pages.
class SharedScaffold extends StatefulWidget {
  /// Creates a shared scaffold.
  const SharedScaffold({
    required this.selectedIndex,
    required this.body,
    Key? key,
  }) : super(key: key);

  /// The selected index
  final int selectedIndex;

  /// The body of the page.
  final Widget body;

  @override
  State<SharedScaffold> createState() => _SharedScaffoldState();
}

class _SharedScaffoldState extends State<SharedScaffold> {
  @override
  Widget build(BuildContext context) => AdaptiveNavigationScaffold(
        selectedIndex: widget.selectedIndex,
        destinations: const <AdaptiveScaffoldDestination>[
          AdaptiveScaffoldDestination(title: 'Page 1', icon: Icons.first_page),
          AdaptiveScaffoldDestination(title: 'Page 2', icon: Icons.last_page),
          AdaptiveScaffoldDestination(title: 'About', icon: Icons.info),
        ],
        appBar: AdaptiveAppBar(title: const Text(App.title)),
        navigationTypeResolver: (BuildContext context) =>
            _drawerSize ? NavigationType.drawer : NavigationType.bottom,
        onDestinationSelected: (int index) async {
          // if there's a drawer, close it
          if (_drawerSize) {
            Navigator.pop(context);
          }

          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/page2');
              break;
            case 2:
              final PackageInfo packageInfo = await PackageInfo.fromPlatform();
              showAboutDialog(
                context: context,
                applicationName: packageInfo.appName,
                applicationVersion: 'v${packageInfo.version}',
                applicationLegalese: 'Copyright © 2022, Acme, Corp.',
              );
              break;
            default:
              throw Exception('Invalid index');
          }
        },
        body: widget.body,
      );

  bool get _drawerSize => MediaQuery.of(context).size.width >= 600;
}

/// The content of the first page.
class Page1View extends StatelessWidget {
  /// Creates a [Page1View].
  const Page1View({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => context.go('/page2'),
              child: const Text('Go to page 2'),
            ),
          ],
        ),
      );
}

/// The content of the second page.
class Page2View extends StatelessWidget {
  /// Creates a [Page2View].
  const Page2View({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to home page'),
            ),
          ],
        ),
      );
}

/// The error scaffold.
class ErrorScaffold extends StatelessWidget {
  /// Creates an [ErrorScaffold]
  const ErrorScaffold({
    required this.body,
    Key? key,
  }) : super(key: key);

  /// The body of this scaffold.
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AdaptiveAppBar(title: const Text('Page Not Found')),
        body: body,
      );
}

/// A view to display error message.
class ErrorView extends StatelessWidget {
  /// Creates an [ErrorView].
  const ErrorView(this.error, {Key? key}) : super(key: key);

  /// The error to display.
  final Exception error;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SelectableText(error.toString()),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Home'),
            ),
          ],
        ),
      );
}
