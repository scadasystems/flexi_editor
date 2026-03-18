import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ComponentWidget extends StatelessWidget {
  final PolicySet policy;

  const ComponentWidget({
    super.key,
    required this.policy,
  });

  static Offset _parentScrollOffset(CanvasModel canvasModel, String? parentId) {
    if (parentId == null) return Offset.zero;
    if (!canvasModel.componentExists(parentId)) return Offset.zero;
    return canvasModel.getComponent(parentId).scrollOffset;
  }

  static int _childrenSignature(CanvasModel canvasModel, List<String> childrenIds) {
    var hash = 0;
    for (final id in childrenIds) {
      if (!canvasModel.componentExists(id)) {
        hash = Object.hash(hash, id, false);
        continue;
      }

      final child = canvasModel.getComponent(id);
      hash = Object.hash(hash, id, true, child.zOrder, child.visible);
    }
    return hash;
  }

  static ({
    double width,
    double height,
    double left,
    double top,
  }) _layout({
    required Component component,
    required double scale,
    required Offset canvasPosition,
    required Offset parentScrollOffset,
  }) {
    final localPosition = component.position - parentScrollOffset;

    final width = scale * component.size.width;
    final height = scale * component.size.height;

    final left = component.parentId == null
        ? scale * localPosition.dx + canvasPosition.dx
        : scale * localPosition.dx;
    final top = component.parentId == null
        ? scale * localPosition.dy + canvasPosition.dy
        : scale * localPosition.dy;

    return (
      width: width,
      height: height,
      left: left,
      top: top,
    );
  }

  Widget _buildSurface({
    required BuildContext context,
    required Component component,
    required CanvasEvent canvasEvent,
    required bool isStartDragSelection,
    required double canvasScale,
  }) {
    final under = policy.showCustomWidgetWithComponentDataUnder(
      context,
      component,
    );
    final body = policy.showComponentBody(component) ?? const SizedBox.shrink();
    final over = policy.showCustomWidgetWithComponentData(context, component);

    final surface = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: under),
        Positioned.fill(child: body),
        Positioned.fill(child: over),
      ],
    );

    if (component.locked) {
      return IgnorePointer(child: surface);
    }

    return MouseRegion(
      onEnter: (_) => policy.onComponentEnter(component.id),
      onExit: (_) => policy.onComponentExit(component.id),
      child: Listener(
        onPointerSignal: (event) {
          if (!component.hasChildren) return;
          if (event is! PointerScrollEvent) return;
          if (event.kind == PointerDeviceKind.trackpad) return;

          final deltaCanvas = Offset(
            event.scrollDelta.dx / canvasScale,
            event.scrollDelta.dy / canvasScale,
          );
          component.updateScrollOffset(deltaCanvas);
          policy.canvasWriter.model.updateComponentLinks(component.id);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: isStartDragSelection
              ? () => policy.onComponentTap(component.id)
              : null,
          onTapDown: isStartDragSelection
              ? (details) {
                  canvasEvent.startTapComponent();
                  policy.onComponentTapDown(component.id, details);
                }
              : null,
          onTapUp: isStartDragSelection
              ? (details) {
                  policy.onComponentTapUp(component.id, details);
                  canvasEvent.stopTapComponent();
                }
              : null,
          onTapCancel: isStartDragSelection
              ? () {
                  policy.onComponentTapCancel(component.id);
                  canvasEvent.stopTapComponent();
                }
              : null,
          onDoubleTapDown: isStartDragSelection
              ? (details) =>
                  policy.onComponentDoubleTapDown(component.id, details)
              : null,
          onDoubleTap: () => policy.onComponentDoubleTap(component.id),
          onScaleStart: isStartDragSelection
              ? (details) {
                  canvasEvent.startTapComponent();
                  policy.onComponentScaleStart(component.id, details);
                }
              : null,
          onScaleUpdate: isStartDragSelection
              ? (details) => policy.onComponentScaleUpdate(component.id, details)
              : null,
          onScaleEnd: isStartDragSelection
              ? (details) {
                  canvasEvent.stopTapComponent();
                  policy.onComponentScaleEnd(component.id, details);
                }
              : null,
          child: surface,
        ),
      ),
    );
  }

  List<Component> _sortedChildren({
    required Component component,
    required CanvasModel canvasModel,
  }) {
    final childOrderIndex = <String, int>{
      for (var i = 0; i < component.childrenIds.length; i++)
        component.childrenIds[i]: i,
    };

    final children =
        component.childrenIds
            .where(canvasModel.componentExists)
            .map(canvasModel.getComponent)
            .where((c) => c.visible)
            .toList()
          ..sort((a, b) {
            final zCompare = a.zOrder.compareTo(b.zOrder);
            if (zCompare != 0) return zCompare;
            return (childOrderIndex[a.id] ?? 0).compareTo(
              childOrderIndex[b.id] ?? 0,
            );
          });

    return children;
  }

  List<Widget> _childWidgets({
    required List<Component> children,
  }) {
    return children
        .map(
          (childComponent) => ChangeNotifierProvider<Component>.value(
            value: childComponent,
            key: ValueKey(childComponent.id),
            child: ComponentWidget(policy: policy),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildContent({
    required Component component,
    required Widget surface,
    required List<Widget> childWidgets,
  }) {
    Widget content = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        surface,
        ...childWidgets,
      ],
    );

    if (component.isScreen) {
      content = ClipRect(child: content);
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final component = context.watch<Component>();
    final canvasEvent = context.read<CanvasEvent>();
    final isStartDragSelection =
        context.select<CanvasEvent, bool>((event) => event.isStartDragSelection);

    final canvasTransform = context.select<CanvasState, ({double scale, Offset position})>(
      (state) => (scale: state.scale, position: state.position),
    );

    final canvasModel = context.read<CanvasModel>();

    final modelDependencies = context.select<
        CanvasModel,
        ({
          Offset parentScrollOffset,
          int childrenSignature,
        })>(
      (model) => (
        parentScrollOffset: _parentScrollOffset(model, component.parentId),
        childrenSignature: _childrenSignature(model, component.childrenIds),
      ),
    );

    final layout = _layout(
      component: component,
      scale: canvasTransform.scale,
      canvasPosition: canvasTransform.position,
      parentScrollOffset: modelDependencies.parentScrollOffset,
    );

    final surface = _buildSurface(
      context: context,
      component: component,
      canvasEvent: canvasEvent,
      isStartDragSelection: isStartDragSelection,
      canvasScale: canvasTransform.scale,
    );

    final children = _sortedChildren(
      component: component,
      canvasModel: canvasModel,
    );
    final childWidgets = _childWidgets(children: children);
    final content = _buildContent(
      component: component,
      surface: surface,
      childWidgets: childWidgets,
    );

    return Positioned(
      left: layout.left,
      top: layout.top,
      width: layout.width,
      height: layout.height,
      child: content,
    );
  }
}
