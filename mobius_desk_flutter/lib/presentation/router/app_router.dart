import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobius_desk_flutter/application/providers/infrastructure_providers.dart';
import 'package:mobius_desk_flutter/application/providers/device_provider.dart';
import 'package:mobius_desk_flutter/application/providers/connection_provider.dart';
import 'package:mobius_desk_flutter/presentation/pages/connect/connect_page.dart';
import 'package:mobius_desk_flutter/presentation/pages/device/device_page.dart';
import 'package:mobius_desk_flutter/presentation/pages/remote/remote_page.dart';
import 'package:mobius_desk_flutter/presentation/pages/setting/setting_page.dart';
import 'package:mobius_desk_flutter/presentation/shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connect',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/connect',
            builder: (context, state) => const ConnectPage(),
          ),
          GoRoute(
            path: '/device',
            builder: (context, state) => const DevicePage(),
          ),
          GoRoute(
            path: '/setting',
            builder: (context, state) => const SettingPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/remote',
        builder: (context, state) => const RemotePage(),
      ),
    ],
  );
});