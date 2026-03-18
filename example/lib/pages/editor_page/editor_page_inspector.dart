part of '../editor_page.dart';

class _Inspector extends StatelessWidget {
  const _Inspector();

  @override
  /// 현재 선택 상태(컴포넌트/링크)에 대한 요약 정보를 표시합니다.
  Widget build(BuildContext context) {
    final editor = context.read<ExampleEditorStore>();
    final editorContext = editor.editorContext;
    final controller = editor.controller;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 280,
      child: Material(
        color: scheme.surface,
        child: Padding(
          padding: const .all(12),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              editorContext.canvasModel,
              controller,
            ]),
            builder: (context, child) {
              final selectedIds = controller.selectedComponentIds.toList();
              final selectedLinkId = controller.selectedLinkId;

              if (selectedLinkId != null) {
                return _InspectorSection(
                  title: 'Link',
                  children: [_InspectorRow(label: 'id', value: selectedLinkId)],
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
                    final rotationRadians = data is EditorShapeData
                        ? data.rotationRadians
                        : null;
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
                    const _InspectorRow(
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
  /// 제목과 행 목록으로 구성된 섹션을 렌더링합니다.
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
  /// 라벨-값 한 줄을 렌더링합니다.
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const .only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
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
