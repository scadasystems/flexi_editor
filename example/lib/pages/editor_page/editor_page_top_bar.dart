part of '../editor_page.dart';

class _FloatingShapePanel extends StatelessWidget {
  const _FloatingShapePanel();

  @override
  /// 현재 도구 상태에 따라 플로팅 도구 패널을 렌더링합니다.
  Widget build(BuildContext context) {
    final editor = context.read<ExampleEditorStore>();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      borderRadius: .circular(12),
      child: Padding(
        padding: const .all(8),
        child: AnimatedBuilder(
          animation: editor.controller,
          builder: (context, child) {
            final controller = editor.controller;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToolButton(
                  icon: Icons.near_me_outlined,
                  selected: controller.tool == EditorTool.select,
                  onPressed: () => controller.setTool(EditorTool.select),
                ),
                _ToolButton(
                  icon: Icons.crop_square_outlined,
                  selected: controller.tool == EditorTool.rectangle,
                  onPressed: () => controller.setTool(EditorTool.rectangle),
                ),
                _ToolButton(
                  icon: Icons.circle_outlined,
                  selected: controller.tool == EditorTool.oval,
                  onPressed: () => controller.setTool(EditorTool.oval),
                ),
                _ToolButton(
                  icon: Icons.polyline_outlined,
                  selected: controller.tool == EditorTool.connector,
                  onPressed: () => controller.setTool(EditorTool.connector),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onAddScreen;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const _TopBar({
    required this.onAddScreen,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  /// 상단 툴바를 렌더링합니다(추가/undo/redo/리셋/디버그 JSON/테마).
  Widget build(BuildContext context) {
    final editor = context.read<ExampleEditorStore>();
    final editorContext = editor.editorContext;
    final undoRedoController = editor.undoRedoController;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: Material(
        color: scheme.surface,
        child: Padding(
          padding: const .symmetric(horizontal: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;

              return Row(
                children: [
                  Text(
                    isCompact ? 'Flexi' : 'Flexi Editor',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: AnimatedBuilder(
                      animation: editor.controller,
                      builder: (context, child) {
                        return Text(
                          switch (editor.controller.tool) {
                            EditorTool.select => 'Select',
                            EditorTool.rectangle => 'Rectangle',
                            EditorTool.oval => 'Oval',
                            EditorTool.connector => 'Connector',
                          },
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  if (!isCompact) const Spacer(),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: AnimatedBuilder(
                          animation: undoRedoController,
                          builder: (context, child) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: onAddScreen,
                                  icon: const Icon(Icons.dashboard_outlined),
                                  tooltip: 'Screen',
                                ),
                                IconButton(
                                  onPressed:
                                      undoRedoController.canUndo ? onUndo : null,
                                  icon: const Icon(Icons.undo),
                                  tooltip: 'Undo',
                                ),
                                IconButton(
                                  onPressed:
                                      undoRedoController.canRedo ? onRedo : null,
                                  icon: const Icon(Icons.redo),
                                  tooltip: 'Redo',
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final json = editorContext.canvasModel
                                        .getFlexi()
                                        .toJson();
                                    final jsonText =
                                        const JsonEncoder.withIndent('  ')
                                            .convert(
                                      json,
                                    );
                                    await showEditorDebugJsonViewerSheet(
                                      context: context,
                                      jsonText: jsonText,
                                    );
                                  },
                                  icon: const Icon(Icons.data_object_outlined),
                                  tooltip: 'Debug JSON',
                                ),
                                Consumer<ThemeModeController>(
                                  builder: (context, controller, child) {
                                    final isDark =
                                        controller.themeMode == ThemeMode.dark;
                                    return IconButton(
                                      onPressed: controller.toggle,
                                      icon: Icon(
                                        isDark
                                            ? Icons.light_mode_outlined
                                            : Icons.dark_mode_outlined,
                                      ),
                                      tooltip:
                                          isDark ? 'Light theme' : 'Dark theme',
                                    );
                                  },
                                ),
                                if (isCompact)
                                  IconButton(
                                    onPressed:
                                        editorContext.canvasState.resetCanvasView,
                                    icon: const Icon(
                                      Icons.center_focus_strong_outlined,
                                    ),
                                    tooltip: 'Reset',
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!isCompact)
                    AnimatedBuilder(
                      animation: editorContext.canvasState,
                      builder: (context, child) {
                        final zoom = (editorContext.canvasState.scale * 100)
                            .round();
                        return Text(
                          'Zoom $zoom%',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  if (!isCompact) const SizedBox(width: 12),
                  if (!isCompact)
                    TextButton(
                      onPressed: editorContext.canvasState.resetCanvasView,
                      child: const Text('Reset'),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  @override
  /// 도구 전환 버튼을 렌더링합니다.
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const .symmetric(vertical: 6),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : null,
          foregroundColor: selected ? scheme.primary : null,
        ),
      ),
    );
  }
}
