import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Alt gezinti sekmeleri.
class HomeTab {
  HomeTab._();

  static const int overview = 0;
  static const int transactions = 1;
  static const int reports = 2;
  static const int budget = 3;
  static const int more = 4;
}

class HomeTabNotifier extends Notifier<int> {
  @override
  int build() => HomeTab.overview;

  void select(int index) => state = index;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, int>(HomeTabNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
