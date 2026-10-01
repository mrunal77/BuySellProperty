import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/router.dart';
import 'src/core/theme.dart';

void main() => runApp(const ProviderScope(child: BuySellApp()));

class BuySellApp extends ConsumerWidget {
  const BuySellApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'BuySellProperty',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: mode,
      routerConfig: router,
    );
  }
}
