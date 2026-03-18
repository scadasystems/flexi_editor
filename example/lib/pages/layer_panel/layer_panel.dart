import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../editor/example_editor_store.dart';
import '../../theme/layer_panel_tokens.dart';
import 'layer_panel_components.dart';
import 'layer_panel_provider.dart';

/// 캔버스의 컴포넌트 트리를 계층 구조로 보여주는 레이어 패널입니다.
class LayerPanel extends StatelessWidget {
  const LayerPanel({super.key});

  @override
  /// 레이어 패널 전용 상태를 Provider로 설치합니다.
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LayerPanelProvider(editor: context.read<ExampleEditorStore>()),
      child: const _LayerPanelView(),
    );
  }
}

class _LayerPanelView extends StatelessWidget {
  const _LayerPanelView();

  @override
  /// 레이어 패널 UI를 렌더링합니다.
  Widget build(BuildContext context) {
    final provider = context.read<LayerPanelProvider>();
    final editorContext = provider.editorContext;
    final controller = provider.controller;
    final tokens = context.layerPanelTokens;

    return Material(
      color: tokens.colors.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: tokens.colors.border)),
        ),
        child: SafeArea(
          left: false,
          right: false,
          top: false,
          bottom: false,
          child: Padding(
            padding: tokens.padding.outer,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                editorContext.canvasModel,
                controller,
                provider,
              ]),
              builder: (context, child) {
                final model = editorContext.canvasModel;

                final expandableIds = provider.expandableComponentIds();
                final canExpand = expandableIds.any(
                  (id) => !provider.expandedIds.contains(id),
                );
                final canCollapse = provider.expandedIds.isNotEmpty;

                final roots =
                    model.components.values
                        .where((c) => c.parentId == null)
                        .toList()
                      ..sort((a, b) {
                        final zCompare = b.zOrder.compareTo(a.zOrder);
                        if (zCompare != 0) return zCompare;
                        return b.id.compareTo(a.id);
                      });

                final items = <Widget>[];
                for (final component in roots) {
                  items.addAll(
                    _buildComponentItems(
                      provider: provider,
                      model: model,
                      componentId: component.id,
                      depth: 0,
                      tokens: tokens,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayerPanelHeader(
                      canExpand: canExpand,
                      canCollapse: canCollapse,
                      onExpandAll: provider.expandAll,
                      onCollapseAll: provider.collapseAll,
                      tokens: tokens,
                    ),
                    SizedBox(height: tokens.padding.headerToListSpacing),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: items.isEmpty
                            ? [
                                Text(
                                  'No components',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: tokens.colors.textSecondary,
                                  ),
                                ),
                              ]
                            : items,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildComponentItems({
    required LayerPanelProvider provider,
    required dynamic model,
    required String componentId,
    required int depth,
    required LayerPanelTokens tokens,
  }) {
    if (!model.componentExists(componentId)) return const [];

    final component = model.getComponent(componentId) as Component;
    final childOrderIndex = <String, int>{
      for (var i = 0; i < component.childrenIds.length; i++)
        component.childrenIds[i]: i,
    };
    final List<Component> children =
        component.childrenIds
            .where((id) => model.componentExists(id) == true)
            .map<Component>((id) => model.getComponent(id) as Component)
            .toList()
          ..sort((a, b) {
            final zCompare = b.zOrder.compareTo(a.zOrder);
            if (zCompare != 0) return zCompare;
            return (childOrderIndex[b.id] ?? 0).compareTo(
              childOrderIndex[a.id] ?? 0,
            );
          });

    final controller = provider.controller;
    final isSelected = controller.isComponentSelected(component.id);
    final isExpandable = children.isNotEmpty;
    final isExpanded = provider.expandedIds.contains(component.id);
    final isHovered = provider.hoveredExpandableId == component.id;
    final isRowHovered = provider.hoveredRowId == component.id;
    final isDragging = provider.draggingComponentId == component.id;
    final isHidden = !component.visible;
    final idTooltipKey = GlobalKey<TooltipState>();
    final shouldShowVisibilityToggle = isRowHovered || isSelected;

    final dragData = LayerPanelDragData(componentId: component.id);
    final titleTextColor = isHidden
        ? tokens.colors.textMuted
        : tokens.colors.textPrimary;
    final iconColor = isHidden
        ? tokens.colors.textMuted
        : tokens.colors.textPrimary;

    final draggableChild = Row(
      children: [
        SizedBox(
          width: tokens.sizes.leadingSlotSize,
          height: tokens.sizes.leadingSlotSize,
          child: isExpandable && (isHovered || isSelected)
              ? IconButton(
                  onPressed: () => provider.toggleExpanded(component.id),
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                  ),
                  iconSize: tokens.sizes.expandIconSize,
                  padding: EdgeInsets.zero,
                  color: tokens.colors.textSecondary,
                  tooltip: isExpanded ? 'Collapse' : 'Expand',
                )
              : Icon(
                  layerPanelIconForComponent(component),
                  size: tokens.sizes.leadingIconSize,
                  color: iconColor,
                ),
        ),
        SizedBox(width: tokens.padding.itemIconTextSpacing),
        Expanded(
          child: provider.editingComponentId == component.id
              ? TextField(
                  controller: provider.nameEditingController,
                  focusNode: provider.nameEditingFocusNode,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    color: tokens.colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => provider.commitNameEdit(save: true),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: component.type == 'screen'
                      ? () {
                          controller.selectSingleComponent(component.id);
                          provider.focusScreen(component.id);
                        }
                      : null,
                  onDoubleTap: () => provider.startNameEdit(component),
                  child: Text(
                    layerPanelDisplayNameForComponent(component),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.1,
                      color: titleTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
      ],
    );

    final longPressDraggableChild = provider.editingComponentId == component.id
        ? draggableChild
        : MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: LongPressDraggable<LayerPanelDragData>(
              data: dragData,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              axis: Axis.vertical,
              onDragStarted: () => provider.onDragStarted(component.id),
              onDragEnd: (_) => provider.onDragEnded(),
              onDragCompleted: () => provider.onDragEnded(),
              onDraggableCanceled: (_, _) => provider.onDragEnded(),
              feedback: buildLayerPanelDragFeedback(
                component: component,
                depth: depth,
                maxWidth: tokens.sizes.width - tokens.sizes.leadingSlotSize,
                tokens: tokens,
              ),
              child: draggableChild,
            ),
          );

    final row = MouseRegion(
      onEnter: (_) {
        provider.setHoveredRowId(component.id);
        if (isExpandable) {
          provider.setHoveredExpandableId(component.id);
        }
        if (!isSelected) {
          idTooltipKey.currentState?.ensureTooltipVisible();
        }
      },
      onExit: (_) {
        if (provider.hoveredRowId == component.id) {
          provider.setHoveredRowId(null);
        }
        if (provider.hoveredExpandableId != component.id) return;
        provider.setHoveredExpandableId(null);
      },
      child: Opacity(
        opacity: isDragging
            ? tokens.opacity.rowDragging
            : isHidden
            ? tokens.opacity.rowHidden
            : 1,
        child: Material(
          color: isSelected
              ? tokens.colors.rowSelected
              : isRowHovered
              ? tokens.colors.rowHover
              : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radius.row),
          child: InkWell(
            borderRadius: BorderRadius.circular(tokens.radius.row),
            onTap: provider.editingComponentId == component.id
                ? null
                : () => controller.selectSingleComponent(component.id),
            child: Padding(
              padding: EdgeInsets.only(
                left:
                    tokens.padding.rowBaseLeft +
                    depth * tokens.padding.rowIndentPerDepth,
                right: tokens.padding.rowRight,
                top: tokens.padding.rowVertical,
                bottom: tokens.padding.rowVertical,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: longPressDraggableChild,
                  ),
                  SizedBox(width: tokens.padding.itemIconTextSpacing),
                  if (shouldShowVisibilityToggle)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            provider.toggleComponentVisible(component.id),
                        child: Padding(
                          padding: const .all(2),
                          child: Icon(
                            component.visible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: tokens.sizes.trailingIconSize,
                            color: tokens.colors.iconMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final rowWithIdTooltip = Tooltip(
      key: idTooltipKey,
      message: component.id,
      child: row,
    );

    final item = Builder(
      builder: (itemContext) {
        return DragTarget<LayerPanelDragData>(
          key: ValueKey('layer-item:${component.id}'),
          onWillAcceptWithDetails: (details) {
            return provider.isDropAllowed(
              draggedId: details.data.componentId,
              targetId: component.id,
            );
          },
          onMove: (details) {
            final box = itemContext.findRenderObject() as RenderBox?;
            if (box == null || !box.hasSize) return;
            final local = box.globalToLocal(details.offset);
            final isAbove = local.dy <= box.size.height / 2;
            provider.onDropMove(
              targetId: component.id,
              insertAbove: isAbove,
            );
          },
          onLeave: (_) => provider.onDropLeave(component.id),
          onAcceptWithDetails: (details) {
            try {
              final draggedId = details.data.componentId;
              final box = itemContext.findRenderObject() as RenderBox?;
              final insertAbove = box == null || !box.hasSize
                  ? (provider.dropTargetComponentId == component.id
                        ? provider.dropTargetInsertAbove
                        : true)
                  : box.globalToLocal(details.offset).dy <= box.size.height / 2;
              provider.clearDropTarget();
              if (!provider.isDropAllowed(
                draggedId: draggedId,
                targetId: component.id,
              )) {
                return;
              }

              if (!model.componentExists(draggedId) ||
                  !model.componentExists(component.id)) {
                return;
              }

              final dragged = model.getComponent(draggedId);
              final target = model.getComponent(component.id);
              if (dragged.parentId == target.parentId) {
                provider.reorderWithinSameParent(
                  draggedId: draggedId,
                  targetId: component.id,
                  insertAbove: insertAbove,
                );
                return;
              }

              if (target.type == 'screen') {
                provider.moveToScreen(
                  draggedId: draggedId,
                  screenId: target.id,
                  insertAbove: insertAbove,
                );
              }
            } finally {
              provider.endDragSession();
            }
          },
          builder: (context, candidateData, rejectedData) {
            final shouldShowIndicator =
                candidateData.isNotEmpty &&
                provider.dropTargetComponentId == component.id;
            if (!shouldShowIndicator) return rowWithIdTooltip;

            final indicatorLeft =
                tokens.padding.rowBaseLeft +
                depth * tokens.padding.rowIndentPerDepth;
            return Stack(
              children: [
                rowWithIdTooltip,
                Positioned(
                  left: indicatorLeft,
                  right: 8,
                  top: provider.dropTargetInsertAbove ? 0 : null,
                  bottom: provider.dropTargetInsertAbove ? null : 0,
                  child: IgnorePointer(
                    child: Container(
                      height: tokens.sizes.dropIndicatorHeight,
                      decoration: BoxDecoration(
                        color: tokens.colors.stateAccent,
                        borderRadius: BorderRadius.circular(
                          tokens.radius.dropIndicator,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    final items = <Widget>[item];
    if (isExpandable && isExpanded) {
      for (final child in children) {
        items.addAll(
          _buildComponentItems(
            provider: provider,
            model: model,
            componentId: child.id,
            depth: depth + 1,
            tokens: tokens,
          ),
        );
      }
    }

    return items;
  }
}
