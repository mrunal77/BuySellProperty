import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();
const _key = 'themeMode';

/// App-wide light/dark theme mode, persisted across restarts.
final themeModeProvider = StateNotifierProvider<ThemeModeStore, ThemeMode>((ref) {
  return ThemeModeStore();
});

class ThemeModeStore extends StateNotifier<ThemeMode> {
  ThemeModeStore() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final v = await _storage.read(key: _key);
    state = switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _storage.write(
      key: _key,
      value: switch (mode) { ThemeMode.light => 'light', ThemeMode.dark => 'dark', _ => 'system' },
    );
  }
}

const _seed = Color(0xFF006244);

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
  inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
);
