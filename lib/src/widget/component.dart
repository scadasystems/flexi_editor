import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flutter/foundation.dart';
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
  late Widget? _componentBody;
  late Map<String, dynamic> _lastDynamicData;
  late Offset _lastPosition;
  late Size _lastSize;
  late double _lastScale;
  late List<String> _lastChildrenIds;

  @override
  void initState() {
    super.initState();
    final componentData = Provider.of<Component>(context, listen: false);
    _componentBody = widget.policy.showComponentBody(componentData);
    _lastDynamicData = Map.from(componentData.toJson()['dynamic_data']);
    _lastPosition = componentData.position;
    _lastSize = componentData.size;
    _lastChildrenIds = List.from(componentData.childrenIds);

    final canvasState = Provider.of<CanvasState>(context, listen: false);
    _lastScale = canvasState.scale;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Component>(
      builder: (context, component, _) {
        final currentDynamicData = component.toJson()['dynamic_data'];

        if (!mapEquals(_lastDynamicData, currentDynamicData)) {
          _componentBody = widget.policy.showComponentBody(component);
          _lastDynamicData = Map.from(currentDynamicData);
        }

        return Consumer2<CanvasState, CanvasEvent>(
          builder: (context, canvasState, canvasEvent, _) {
            // Only calculate positions if necessary values changed
            final needsPositionUpdate = component.position != _lastPosition ||
                component.size != _lastSize ||
                canvasState.scale != _lastScale;

            double left, top, width, height;
            if (needsPositionUpdate) {
              left = canvasState.scale * component.position.dx +
                  canvasState.position.dx;
              top = canvasState.scale * component.position.dy +
                  canvasState.position.dy;
              width = canvasState.scale * component.size.width;
              height = canvasState.scale * component.size.height;

              _lastPosition = component.position;
              _lastSize = component.size;
              _lastScale = canvasState.scale;
            } else {
              // Use cached calculations
              left = _lastScale * _lastPosition.dx + canvasState.position.dx;
              top = _lastScale * _lastPosition.dy + canvasState.position.dy;
              width = _lastScale * _lastSize.width;
              height = _lastScale * _lastSize.height;
            }

            final hasChildren =
                component.type == 'screen' && component.childrenIds.isNotEmpty;
            if (!listEquals(component.childrenIds, _lastChildrenIds)) {
              _lastChildrenIds = List.from(component.childrenIds);
            }

            return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: MouseRegion(
                onEnter: !hasChildren
                    ? (_) => widget.policy.onComponentEnter(component.id)
                    : null,
                onExit: !hasChildren
                    ? (_) => widget.policy.onComponentExit(component.id)
                    : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: canvasEvent.isStartDragSelection
                      ? () => widget.policy.onComponentTap(component.id)
                      : null,
                  onTapDown: canvasEvent.isStartDragSelection
                      ? (details) {
                          canvasEvent.startTapComponent();
                          widget.policy
                              .onComponentTapDown(component.id, details);
                        }
                      : null,
                  onTapUp: canvasEvent.isStartDragSelection
                      ? (details) {
                          canvasEvent.endTapComponent();
                          widget.policy.onComponentTapUp(component.id, details);
                        }
                      : null,
                  onTapCancel: canvasEvent.isStartDragSelection
                      ? () => widget.policy.onComponentTapCancel(component.id)
                      : null,
                  onDoubleTap: !hasChildren
                      ? () => widget.policy.onComponentDoubleTap(component.id)
                      : null,
                  onScaleStart: !hasChildren
                      ? canvasEvent.isStartDragSelection
                          ? (details) => widget.policy
                              .onComponentScaleStart(component.id, details)
                          : null
                      : null,
                  onScaleUpdate: !hasChildren
                      ? canvasEvent.isStartDragSelection
                          ? (details) => widget.policy
                              .onComponentScaleUpdate(component.id, details)
                          : null
                      : null,
                  onScaleEnd: !hasChildren
                      ? canvasEvent.isStartDragSelection
                          ? (details) {
                              canvasEvent.endTapComponent();
                              widget.policy
                                  .onComponentScaleEnd(component.id, details);
                            }
                          : null
                      : null,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        width: component.size.width,
                        height: component.size.height,
                        child: Container(
                          transform: Matrix4.identity()
                            ..scale(canvasState.scale),
                          child: _componentBody,
                        ),
                      ),
                      widget.policy.showCustomWidgetWithComponentData(
                          context, component),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
