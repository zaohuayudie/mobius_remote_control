import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobius_desk_flutter/core/theme.dart';
import 'package:mobius_desk_flutter/infrastructure/storage/local_storage.dart';
import 'package:mobius_desk_flutter/presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.instance;
  runApp(const ProviderScope(child: MobiusDeskApp()));
}

class MobiusDeskApp extends ConsumerWidget {
  const MobiusDeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'MobiusDesk',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}