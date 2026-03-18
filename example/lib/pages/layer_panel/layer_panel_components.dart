import 'package:flexi_editor/flexi_editor.dart';
import 'package:flutter/material.dart';

import '../../theme/layer_panel_tokens.dart';

class LayerPanelHeader extends StatelessWidget {
  final bool canExpand;
  final bool canCollapse;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;
  final LayerPanelTokens tokens;

  const LayerPanelHeader({
    super.key,
    required this.canExpand,
    required this.canCollapse,
    required this.onExpandAll,
    required this.onCollapseAll,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Layers',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: canExpand ? onExpandAll : null,
          icon: const Icon(Icons.unfold_more),
          tooltip: 'Expand all',
          iconSize: tokens.sizes.headerIconSize,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(
            width: tokens.sizes.headerButtonSize,
            height: tokens.sizes.headerButtonSize,
          ),
          color: tokens.colors.textSecondary,
        ),
        IconButton(
          onPressed: canCollapse ? onCollapseAll : null,
          icon: const Icon(Icons.unfold_less),
          tooltip: 'Collapse all',
          iconSize: tokens.sizes.headerIconSize,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(
            width: tokens.sizes.headerButtonSize,
            height: tokens.sizes.headerButtonSize,
          ),
          color: tokens.colors.textSecondary,
        ),
      ],
    );
  }
}

class LayerPanelDragData {
  final String componentId;

  const LayerPanelDragData({required this.componentId});
}

String layerPanelFallbackLabelForComponent(Component component) {
  if (component.subtype != null) {
    return '${component.type}/${component.subtype}';
  }
  return component.type;
}

String layerPanelDisplayNameForComponent(Component component) {
  final name = component.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  return layerPanelFallbackLabelForComponent(component);
}

IconData layerPanelIconForComponent(Component component) {
  if (component.type == 'screen') return Icons.dashboard_outlined;
  if (component.type == 'shape') {
    if (component.subtype == 'rect') return Icons.crop_square_outlined;
    if (component.subtype == 'oval') return Icons.circle_outlined;
    return Icons.category_outlined;
  }
  return Icons.layers_outlined;
}

Widget buildLayerPanelDragFeedback({
  required Component component,
  required int depth,
  required double maxWidth,
  required LayerPanelTokens tokens,
}) {
  return Material(
    color: Colors.transparent,
    child: Opacity(
      opacity: tokens.opacity.dragFeedback,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.colors.dragFeedbackBackground,
          borderRadius: BorderRadius.circular(tokens.radius.dragFeedback),
          boxShadow: [
            BoxShadow(
              blurRadius: tokens.sizes.dragFeedbackShadowBlurRadius,
              offset: tokens.sizes.dragFeedbackShadowOffset,
              color: tokens.colors.dragFeedbackShadowColor,
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left:
                  tokens.padding.rowBaseLeft +
                  depth * tokens.padding.rowIndentPerDepth,
              right: tokens.padding.dragFeedbackRight,
              top: tokens.padding.dragFeedbackVertical,
              bottom: tokens.padding.dragFeedbackVertical,
            ),
            child: Row(
              children: [
                Icon(
                  layerPanelIconForComponent(component),
                  size: tokens.sizes.leadingIconSize,
                  color: tokens.colors.textPrimary,
                ),
                SizedBox(width: tokens.padding.itemIconTextSpacing),
                Expanded(
                  child: Text(
                    layerPanelDisplayNameForComponent(component),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.1,
                      color: tokens.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
