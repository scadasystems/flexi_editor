import 'package:flutter/material.dart';

import 'layer_panel_tokens.dart';

class ExampleAppTheme {
  static const _seedColor = Color(0xFF2563EB);

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    extensions: const [LayerPanelTheme(tokens: LayerPanelTokens.light)],
    scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    useMaterial3: true,
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    extensions: const [LayerPanelTheme(tokens: LayerPanelTokens.dark)],
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    useMaterial3: true,
  );
}
