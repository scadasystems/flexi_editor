import 'dart:math' as math;

import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../editor/editor_controller.dart';
import '../editor/editor_models.dart';
import '../editor/example_policy_set.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final EditorController _controller;
  late final ExamplePolicySet _policySet;
  late final FlexiEditorContext _editorContext;

  String? _draftComponentId;
  Rect? _lastDragRect;

  @override
  void initState() {
    super.initState();
    _controller = EditorController();
    _policySet = ExamplePolicySet(controller: _controller);
    _editorContext = FlexiEditorContext(_policySet);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelectionRectStart() {
    _lastDragRect = null;
    if (_controller.tool == EditorTool.select) {
      _controller.clearSelection();
    }
  }

  void _onSelectionRectUpdate(Rect selectionRect) {
    _lastDragRect = selectionRect;

    final tool = _controller.tool;
    if (tool == EditorTool.rectangle || tool == EditorTool.oval) {
      _upsertDraftShape(selectionRect, tool);
      return;
    }

    if (tool == EditorTool.select) {
      final ids = _hitTestComponentsInRect(selectionRect);
      _controller.setSelectedComponents(ids);
    }
  }

  void _onSelectionRectEnd() {
    final tool = _controller.tool;
    final rect = _lastDragRect;

    if ((tool == EditorTool.rectangle || tool == EditorTool.oval) &&
        _draftComponentId != null) {
      final id = _draftComponentId!;
      _draftComponentId = null;

      final finalized = rect != null &&
          rect.size.width >= 8 &&
          rect.size.height >= 8;

      if (!finalized) {
        if (_editorContext.canvasModel.componentExists(id)) {
          _editorContext.canvasModel.removeComponent(id);
        }
        return;
      }

      _controller
        ..selectSingleComponent(id)
        ..setTool(EditorTool.select);

      return;
    }

    _draftComponentId = null;
    _lastDragRect = null;
  }

  Iterable<String> _hitTestComponentsInRect(Rect selectionRect) sync* {
    for (final component in _editorContext.canvasModel.components.values) {
      final componentRect = Rect.fromLTWH(
        component.position.dx,
        component.position.dy,
        component.size.width,
        component.size.height,
      );
      if (selectionRect.overlaps(componentRect)) {
        yield component.id;
      }
    }
  }

  void _upsertDraftShape(Rect rect, EditorTool tool) {
    final subtype = tool == EditorTool.oval ? 'oval' : 'rect';

    final id = _draftComponentId;
    if (id == null) {
      final component = Component<EditorShapeData>(
        type: 'shape',
        subtype: subtype,
        position: rect.topLeft,
        size: rect.size,
        data: const EditorShapeData(
          fillColorValue: 0xFFFFFFFF,
          strokeColorValue: 0xFF111827,
          strokeWidth: 1,
          cornerRadius: 12,
          rotationRadians: 0,
        ),
      );
      _draftComponentId = _editorContext.canvasModel.addComponent(component);
      return;
    }

    if (!_editorContext.canvasModel.componentExists(id)) {
      _draftComponentId = null;
      return;
    }

    final component = _editorContext.canvasModel.getComponent(id);
    component
      ..setPosition(rect.topLeft)
      ..setSize(rect.size);
  }

  void _onKeyboardEvent(FocusNode node, KeyEvent keyEvent) {
    if (keyEvent is! KeyDownEvent) return;

    final key = keyEvent.logicalKey;
    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isCmdOrCtrl = isMeta || isCtrl;

    if (key == LogicalKeyboardKey.escape) {
      _controller
        ..clearPendingConnector()
        ..setTool(EditorTool.select);
      return;
    }

    if (isCmdOrCtrl && key == LogicalKeyboardKey.digit0) {
      _editorContext.canvasState.resetCanvasView();
      return;
    }

    if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
      final selectedLinkId = _controller.selectedLinkId;
      if (selectedLinkId != null &&
          _editorContext.canvasModel.linkExists(selectedLinkId)) {
        _editorContext.canvasModel.removeLink(selectedLinkId);
      }

      final selectedComponentIds =
          _controller.selectedComponentIds.toList(growable: false);
      for (final id in selectedComponentIds) {
        if (_editorContext.canvasModel.componentExists(id)) {
          _editorContext.policySet.canvasWriter.model.removeComponentWithChildren(
            id,
          );
        }
      }

      _controller.clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: SafeArea(
          child: Row(
            children: [
              const _ToolRail(),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(editorContext: _editorContext),
                    Expanded(
                      child: Padding(
                        padding: const .all(12),
                        child: ClipRRect(
                          borderRadius: .circular(12),
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFFFFF),
                            ),
                            child: FlexiEditor(
                              flexiEditorContext: _editorContext,
                              onSelectionRectStart: _onSelectionRectStart,
                              onSelectionRectUpdate: _onSelectionRectUpdate,
                              onSelectionRectEnd: _onSelectionRectEnd,
                              onKeyboardEvent: _onKeyboardEvent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Inspector(editorContext: _editorContext),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final FlexiEditorContext editorContext;

  const _TopBar({required this.editorContext});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: const Color(0xFFFFFFFF),
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
                    child: Consumer<EditorController>(
                      builder: (context, controller, child) {
                        return Text(
                          switch (controller.tool) {
                            EditorTool.select => 'Select',
                            EditorTool.rectangle => 'Rectangle',
                            EditorTool.oval => 'Oval',
                            EditorTool.connector => 'Connector',
                          },
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  if (!isCompact)
                    AnimatedBuilder(
                      animation: editorContext.canvasState,
                      builder: (context, child) {
                        final zoom =
                            (editorContext.canvasState.scale * 100).round();
                        return Text(
                          'Zoom $zoom%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        );
                      },
                    ),
                  if (!isCompact) const SizedBox(width: 12),
                  if (isCompact)
                    IconButton(
                      onPressed: editorContext.canvasState.resetCanvasView,
                      icon: const Icon(Icons.center_focus_strong_outlined),
                      tooltip: 'Reset',
                    )
                  else
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

class _ToolRail extends StatelessWidget {
  const _ToolRail();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Material(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const .symmetric(vertical: 12),
          child: Consumer<EditorController>(
            builder: (context, controller, child) {
              return Column(
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(vertical: 6),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor:
              selected ? const Color(0xFF2563EB).withValues(alpha: 0.12) : null,
          foregroundColor: selected ? const Color(0xFF2563EB) : null,
        ),
      ),
    );
  }
}

class _Inspector extends StatelessWidget {
  final FlexiEditorContext editorContext;

  const _Inspector({required this.editorContext});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Material(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const .all(12),
          child: AnimatedBuilder(
            animation: Listenable.merge([editorContext.canvasModel, context.watch<EditorController>()]),
            builder: (context, child) {
              final controller = context.read<EditorController>();
              final selectedIds = controller.selectedComponentIds.toList();
              final selectedLinkId = controller.selectedLinkId;

              if (selectedLinkId != null) {
                return _InspectorSection(
                  title: 'Link',
                  children: [
                    _InspectorRow(label: 'id', value: selectedLinkId),
                  ],
                );
              }

              if (selectedIds.length == 1) {
                final id = selectedIds.single;
                final component = editorContext.canvasModel.componentExists(id)
                    ? editorContext.canvasModel.getComponent(id)
                    : null;

                if (component == null) {
                  return const _InspectorSection(
                    title: 'Selection',
                    children: [
                      _InspectorRow(label: 'status', value: 'missing'),
                    ],
                  );
                }

                return AnimatedBuilder(
                  animation: component,
                  builder: (context, child) {
                    final data = component.data;
                    final rotationRadians =
                        data is EditorShapeData ? data.rotationRadians : null;
                    final rotationDegrees = rotationRadians == null
                        ? null
                        : rotationRadians * 180 / math.pi;

                    return _InspectorSection(
                      title: 'Component',
                      children: [
                        _InspectorRow(label: 'id', value: component.id),
                        _InspectorRow(label: 'type', value: component.type),
                        if (component.subtype != null)
                          _InspectorRow(
                            label: 'subtype',
                            value: component.subtype!,
                          ),
                        _InspectorRow(
                          label: 'x',
                          value: component.position.dx.toStringAsFixed(0),
                        ),
                        _InspectorRow(
                          label: 'y',
                          value: component.position.dy.toStringAsFixed(0),
                        ),
                        _InspectorRow(
                          label: 'w',
                          value: component.size.width.toStringAsFixed(0),
                        ),
                        _InspectorRow(
                          label: 'h',
                          value: component.size.height.toStringAsFixed(0),
                        ),
                        if (rotationDegrees != null)
                          _InspectorRow(
                            label: 'rotate',
                            value: '${rotationDegrees.toStringAsFixed(1)}°',
                          ),
                      ],
                    );
                  },
                );
              }

              return _InspectorSection(
                title: 'Selection',
                children: [
                  _InspectorRow(
                    label: 'components',
                    value: selectedIds.length.toString(),
                  ),
                  _InspectorRow(
                    label: 'links',
                    value: selectedLinkId == null ? '0' : '1',
                  ),
                  if (controller.pendingConnectorSourceComponentId != null)
                    _InspectorRow(
                      label: 'connector',
                      value: 'source selected',
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

class _InspectorSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InspectorSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}

class _InspectorRow extends StatelessWidget {
  final String label;
  final String value;

  const _InspectorRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
