import 'package:flutter/material.dart';

import 'pages/editor_page.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: .fromSeed(seedColor: const Color(0xFF2563EB)),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Flexi Editor Figma Clone',
      theme: theme,
      home: const EditorPage(),
    );
  }
}
