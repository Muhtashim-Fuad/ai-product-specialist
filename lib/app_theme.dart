import 'package:flutter/material.dart';

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      elevation: 2,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black54,
      centerTitle: true,
    ),
  );
}