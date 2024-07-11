import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
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
    final componentData = Provider.of<ComponentData>(context);
    final canvasState = Provider.of<CanvasState>(context);
    final canvasEvent = Provider.of<CanvasEvent>(context);

    return Positioned(
      left: canvasState.scale * componentData.position.dx + canvasState.position.dx,
      top: canvasState.scale * componentData.position.dy + canvasState.position.dy,
      width: canvasState.scale * componentData.size.width,
      height: canvasState.scale * componentData.size.height,
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          policy.onComponentPointerSignal(componentData.id, event);
        },
        child: MouseRegion(
          onEnter: (_) => policy.onComponentEnter(componentData.id),
          onExit: (_) => policy.onComponentExit(componentData.id),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: canvasEvent.isStartDragSelection //
                ? () => policy.onComponentTap(componentData.id)
                : null,
            onTapDown: canvasEvent.isStartDragSelection
                ? (TapDownDetails details) => policy.onComponentTapDown(componentData.id, details)
                : null,
            onTapUp: canvasEvent.isStartDragSelection
                ? (TapUpDetails details) => policy.onComponentTapUp(componentData.id, details)
                : null,
            onTapCancel: canvasEvent.isStartDragSelection //
                ? () => policy.onComponentTapCancel(componentData.id)
                : null,
            onScaleStart: canvasEvent.isStartDragSelection
                ? (details) => policy.onComponentScaleStart(componentData.id, details)
                : null,
            onScaleUpdate: canvasEvent.isStartDragSelection
                ? (details) => policy.onComponentScaleUpdate(componentData.id, details)
                : null,
            onScaleEnd: canvasEvent.isStartDragSelection
                ? (details) => policy.onComponentScaleEnd(componentData.id, details)
                : null,
            onLongPress: () => policy.onComponentLongPress(componentData.id),
            onLongPressStart: (details) => policy.onComponentLongPressStart(componentData.id, details),
            onLongPressMoveUpdate: (details) => policy.onComponentLongPressMoveUpdate(componentData.id, details),
            onLongPressEnd: (details) => policy.onComponentLongPressEnd(componentData.id, details),
            onLongPressUp: () => policy.onComponentLongPressUp(componentData.id),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: componentData.size.width,
                  height: componentData.size.height,
                  child: Container(
                    transform: Matrix4.identity()..scale(canvasState.scale),
                    child: policy.showComponentBody(componentData),
                  ),
                ),
                policy.showCustomWidgetWithComponentData(context, componentData),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
