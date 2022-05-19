// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/data.dart';

void main() => runApp(App());

/// The main app.
class App extends StatelessWidget {
  /// Creates an [App].
  App({Key? key}) : super(key: key);

  final LoginInfo _loginInfo = LoginInfo();

  /// The title of the app.
  static const String title = 'GoRouter Example: Navigator Builder';

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
        name: 'home',
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            HomeScreenNoLogout(families: Families.data),
        routes: <GoRoute>[
          GoRoute(
            name: 'family',
            path: 'family/:fid',
            builder: (BuildContext context, GoRouterState state) {
              final Family family = Families.family(state.params['fid']!);
              return FamilyScreen(family: family);
            },
            routes: <GoRoute>[
              GoRoute(
                name: 'person',
                path: 'person/:pid',
                builder: (BuildContext context, GoRouterState state) {
                  final Family family = Families.family(state.params['fid']!);
                  final Person person = family.person(state.params['pid']!);
                  return PersonScreen(family: family, person: person);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
    ],

    // redirect to the login page if the user is not logged in
    redirect: (GoRouterState state) {
      // if the user is not logged in, they need to login
      final bool loggedIn = _loginInfo.loggedIn;
      final String loginloc = state.namedLocation('login');
      final bool loggingIn = state.subloc == loginloc;

      // bundle the location the user is coming from into a query parameter
      final String homeloc = state.namedLocation('home');
      final String fromloc = state.subloc == homeloc ? '' : state.subloc;
      if (!loggedIn) {
        return loggingIn
            ? null
            : state.namedLocation(
                'login',
                queryParams: <String, String>{
                  if (fromloc.isNotEmpty) 'from': fromloc
                },
              );
      }

      // if the user is logged in, send them where they were going before (or
      // home if they weren't going anywhere)
      if (loggingIn) {
        return state.queryParams['from'] ?? homeloc;
      }

      // no need to redirect at all
      return null;
    },

    // changes on the listenable will cause the router to refresh it's route
    refreshListenable: _loginInfo,

    // add a wrapper around the navigator to:
    // - put loginInfo into the widget tree, and to
    // - add an overlay to show a logout option
    navigatorBuilder:
        (BuildContext context, GoRouterState state, Widget child) =>
            ChangeNotifierProvider<LoginInfo>.value(
      value: _loginInfo,
      builder: (BuildContext context, Widget? _) {
        debugPrint('navigatorBuilder: ${state.subloc}');
        return _loginInfo.loggedIn ? AuthOverlay(child: child) : child;
      },
    ),
  );
}

/// A simple class for placing an exit button on top of all screens.
class AuthOverlay extends StatelessWidget {
  /// Creates an [AuthOverlay].
  const AuthOverlay({required this.child, Key? key}) : super(key: key);

  /// The child subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          child,
          Positioned(
            top: 90,
            right: 4,
            child: ElevatedButton(
              onPressed: () {
                context.read<LoginInfo>().logout();
                context.goNamed('home'); // clear out the `from` query param
              },
              child: const Icon(Icons.logout),
            ),
          ),
        ],
      );
}

/// The home screen without a logout button.
class HomeScreenNoLogout extends StatelessWidget {
  /// Creates a [HomeScreenNoLogout].
  const HomeScreenNoLogout({required this.families, Key? key})
      : super(key: key);

  /// The list of families.
  final List<Family> families;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        body: ListView(
          children: <Widget>[
            for (final Family f in families)
              ListTile(
                title: Text(f.name),
                onTap: () => context
                    .goNamed('family', params: <String, String>{'fid': f.id}),
              )
          ],
        ),
      );
}

/// The screen that shows a list of persons in a family.
class FamilyScreen extends StatelessWidget {
  /// Creates a [FamilyScreen].
  const FamilyScreen({required this.family, Key? key}) : super(key: key);

  /// The family to display.
  final Family family;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(family.name)),
        body: ListView(
          children: <Widget>[
            for (final Person p in family.people)
              ListTile(
                title: Text(p.name),
                onTap: () => context.go('/family/${family.id}/person/${p.id}'),
              ),
          ],
        ),
      );
}

/// The person screen.
class PersonScreen extends StatelessWidget {
  /// Creates a [PersonScreen].
  const PersonScreen({required this.family, required this.person, Key? key})
      : super(key: key);

  /// The family this person belong to.
  final Family family;

  /// The person to be displayed.
  final Person person;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(person.name)),
        body: Text('${person.name} ${family.name} is ${person.age} years old'),
      );
}

/// The login screen.
class LoginScreen extends StatelessWidget {
  /// Creates a [LoginScreen].
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(App.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  // log a user in, letting all the listeners know
                  context.read<LoginInfo>().login('test-user');
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
}
