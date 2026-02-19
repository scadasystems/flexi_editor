import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ComponentWidget extends StatefulWidget {
  final PolicySet policy;

  const ComponentWidget({
    super.key,
    required this.policy,
  });

  @override
  State<ComponentWidget> createState() => _ComponentWidgetState();
}

class _ComponentWidgetState extends State<ComponentWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<Component, CanvasState, CanvasEvent>(
      builder: (context, component, canvasState, canvasEvent, _) {
        final hasChildren = component.isScreen && component.hasChildren;

        final left =
            canvasState.scale * component.position.dx + canvasState.position.dx;
        final top =
            canvasState.scale * component.position.dy + canvasState.position.dy;
        final width = canvasState.scale * component.size.width;
        final height = canvasState.scale * component.size.height;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: canvasEvent.isStartDragSelection
                ? () => widget.policy.onComponentTap(component.id)
                : null,
            onTapDown: canvasEvent.isStartDragSelection
                ? (details) {
                    widget.policy.onComponentTapDown(component.id, details);
                    canvasEvent.startTapComponent();
                  }
                : null,
            onTapUp: canvasEvent.isStartDragSelection
                ? (details) {
                    widget.policy.onComponentTapUp(component.id, details);
                    canvasEvent.stopTapComponent();
                  }
                : null,
            onTapCancel: canvasEvent.isStartDragSelection
                ? () => widget.policy.onComponentTapCancel(component.id)
                : null,
            onDoubleTapDown: canvasEvent.isStartDragSelection
                ? (details) => widget.policy.onComponentDoubleTapDown(
                    component.id,
                    details,
                  )
                : null,
            onDoubleTap: !hasChildren
                ? () => widget.policy.onComponentDoubleTap(component.id)
                : null,
            onSecondaryTapDown: !hasChildren
                ? (details) => widget.policy.onComponentSecondaryTap(
                    context,
                    component.id,
                    details,
                  )
                : null,
            onScaleStart: !hasChildren
                ? canvasEvent.isStartDragSelection && !component.locked
                      ? (details) => widget.policy.onComponentScaleStart(
                          component.id,
                          details,
                        )
                      : null
                : null,
            onScaleUpdate: !hasChildren
                ? canvasEvent.isStartDragSelection && !component.locked
                      ? (details) => widget.policy.onComponentScaleUpdate(
                          component.id,
                          details,
                        )
                      : null
                : null,
            onScaleEnd: !hasChildren
                ? canvasEvent.isStartDragSelection && !component.locked
                      ? (details) {
                          canvasEvent.stopTapComponent();
                          widget.policy.onComponentScaleEnd(
                            component.id,
                            details,
                          );
                        }
                      : null
                : null,
            child: MouseRegion(
              onEnter: !hasChildren
                  ? (_) => widget.policy.onComponentEnter(component.id)
                  : null,
              onExit: !hasChildren
                  ? (_) => widget.policy.onComponentExit(component.id)
                  : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: component.size.width,
                    height: component.size.height,
                    child: Container(
                      transform: Matrix4.diagonal3Values(
                        canvasState.scale,
                        canvasState.scale,
                        1.0,
                      ),
                      child: widget.policy.showComponentBody(component),
                    ),
                  ),
                  widget.policy.showCustomWidgetWithComponentData(
                    context,
                    component,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
