import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routing/app_router.dart';
import 'theme/diablo_theme.dart';

class MvhsFootballApp extends ConsumerWidget {
  const MvhsFootballApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MVHS Football',
      debugShowCheckedModeBanner: false,
      theme: DiabloTheme.light,
      darkTheme: DiabloTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
