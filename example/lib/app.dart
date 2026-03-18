import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/editor_page.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeModeController(),
      child: Consumer<ThemeModeController>(
        builder: (context, controller, child) {
          return MaterialApp(
            title: 'Flexi Editor Figma Clone',
            theme: ExampleAppTheme.light,
            darkTheme: ExampleAppTheme.dark,
            themeMode: controller.themeMode,
            home: const EditorPage(),
          );
        },
      ),
    );
  }
}
