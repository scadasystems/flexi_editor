import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Component extends StatelessWidget {
  final PolicySet policy;

  const Component({
    super.key,
    required this.policy,
  });

  @override
  Widget build(BuildContext context) {
    final component = Provider.of<ComponentData>(context);
    final canvasState = Provider.of<CanvasState>(context);
    final canvasEvent = Provider.of<CanvasEvent>(context);

    final left = canvasState.scale * component.position.dx + canvasState.position.dx;
    final top = canvasState.scale * component.position.dy + canvasState.position.dy;
    final width = canvasState.scale * component.size.width;
    final height = canvasState.scale * component.size.height;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          policy.onComponentPointerSignal(component.id, event);
        },
        child: MouseRegion(
          onEnter: (_) => policy.onComponentEnter(component.id),
          onExit: (_) => policy.onComponentExit(component.id),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: canvasEvent.isStartDragSelection //
                ? () => policy.onComponentTap(component.id)
                : null,
            onTapDown: component.childrenIds.isNotEmpty
                ? null
                : canvasEvent.isStartDragSelection
                    ? (TapDownDetails details) => policy.onComponentTapDown(component.id, details)
                    : null,
            onTapUp: component.childrenIds.isNotEmpty
                ? null
                : canvasEvent.isStartDragSelection
                    ? (TapUpDetails details) => policy.onComponentTapUp(component.id, details)
                    : null,
            onTapCancel: canvasEvent.isStartDragSelection //
                ? () => policy.onComponentTapCancel(component.id)
                : null,
            onScaleStart: component.childrenIds.isNotEmpty
                ? null
                : canvasEvent.isStartDragSelection
                    ? (details) => policy.onComponentScaleStart(component.id, details)
                    : null,
            onScaleUpdate: component.childrenIds.isNotEmpty
                ? null
                : canvasEvent.isStartDragSelection
                    ? (details) => policy.onComponentScaleUpdate(component.id, details)
                    : null,
            onScaleEnd: component.childrenIds.isNotEmpty
                ? null
                : canvasEvent.isStartDragSelection
                    ? (details) => policy.onComponentScaleEnd(component.id, details)
                    : null,
            onLongPress: () => policy.onComponentLongPress(component.id),
            onLongPressStart: (details) => policy.onComponentLongPressStart(component.id, details),
            onLongPressMoveUpdate: (details) => policy.onComponentLongPressMoveUpdate(component.id, details),
            onLongPressEnd: (details) => policy.onComponentLongPressEnd(component.id, details),
            onLongPressUp: () => policy.onComponentLongPressUp(component.id),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: component.size.width,
                  height: component.size.height,
                  child: Container(
                    transform: Matrix4.identity()..scale(canvasState.scale),
                    child: policy.showComponentBody(component),
                  ),
                ),
                policy.showCustomWidgetWithComponentData(context, component),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
