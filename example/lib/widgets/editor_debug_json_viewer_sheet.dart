import 'package:flutter/material.dart';

Future<void> showEditorDebugJsonViewerSheet({
  required BuildContext context,
  required String jsonText,
}) {
  final scrim = Theme.of(context).colorScheme.scrim;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: scrim.withValues(alpha: 0.5),
    builder: (context) {
      return EditorDebugJsonViewerSheet(jsonText: jsonText);
    },
  );
}

class EditorDebugJsonViewerSheet extends StatelessWidget {
  final String jsonText;

  const EditorDebugJsonViewerSheet({super.key, required this.jsonText});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 920),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: .circular(16)),
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.82,
            child: Column(
              children: [
                Padding(
                  padding: const .all(12),
                  child: Row(
                    children: [
                      const Text(
                        'Editor JSON',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _EditorDebugJsonViewerSheetBody(jsonText: jsonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorDebugJsonViewerSheetBody extends StatefulWidget {
  final String jsonText;

  const _EditorDebugJsonViewerSheetBody({required this.jsonText});

  @override
  State<_EditorDebugJsonViewerSheetBody> createState() =>
      _EditorDebugJsonViewerSheetBodyState();
}

class _EditorDebugJsonViewerSheetBodyState
    extends State<_EditorDebugJsonViewerSheetBody> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _verticalController,
      child: SingleChildScrollView(
        controller: _verticalController,
        padding: const .all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            widget.jsonText,
            style: const TextStyle(
              fontSize: 12,
              height: 1.25,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
