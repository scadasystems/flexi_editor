import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Component extends StatefulWidget {
  final PolicySet policy;

  const Component({
    super.key,
    required this.policy,
  });

  @override
  State<Component> createState() => _ComponentState();
}

class _ComponentState extends State<Component> {
  late Widget? _componentBody;
  late Map<String, dynamic> _lastDynamicData;

  @override
  void initState() {
    super.initState();
    final componentData = Provider.of<ComponentData>(context, listen: false);
    _componentBody = widget.policy.showComponentBody(componentData);
    _lastDynamicData = Map.from(componentData.toJson()['dynamic_data']);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ComponentData, CanvasState, CanvasEvent>(
      builder: (context, component, canvasState, canvasEvent, _) {
        final currentDynamicData = component.toJson()['dynamic_data'];

        if (!mapEquals(_lastDynamicData, currentDynamicData)) {
          _componentBody = widget.policy.showComponentBody(component);
          _lastDynamicData = Map.from(currentDynamicData);
        }

        final left = canvasState.scale * component.position.dx + canvasState.position.dx;
        final top = canvasState.scale * component.position.dy + canvasState.position.dy;
        final width = canvasState.scale * component.size.width;
        final height = canvasState.scale * component.size.height;

        final hasChildren = component.childrenIds.isNotEmpty;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: MouseRegion(
            onEnter: !hasChildren ? (_) => widget.policy.onComponentEnter(component.id) : null,
            onExit: !hasChildren ? (_) => widget.policy.onComponentExit(component.id) : null,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: canvasEvent.isStartDragSelection //
                  ? () => widget.policy.onComponentTap(component.id)
                  : null,
              onTapDown: canvasEvent.isStartDragSelection
                  ? (details) {
                      canvasEvent.startTapComponent();
                      widget.policy.onComponentTapDown(component.id, details);
                    }
                  : null,
              onTapUp: canvasEvent.isStartDragSelection
                  ? (details) {
                      canvasEvent.endTapComponent();
                      widget.policy.onComponentTapUp(component.id, details);
                    }
                  : null,
              onTapCancel: canvasEvent.isStartDragSelection //
                  ? () => widget.policy.onComponentTapCancel(component.id)
                  : null,
              onDoubleTap: !hasChildren ? () => widget.policy.onComponentDoubleTap(component.id) : null,
              onScaleStart: !hasChildren
                  ? canvasEvent.isStartDragSelection
                      ? (details) => widget.policy.onComponentScaleStart(component.id, details)
                      : null
                  : null,
              onScaleUpdate: !hasChildren
                  ? canvasEvent.isStartDragSelection
                      ? (details) => widget.policy.onComponentScaleUpdate(component.id, details)
                      : null
                  : null,
              onScaleEnd: !hasChildren
                  ? canvasEvent.isStartDragSelection
                      ? (details) {
                          canvasEvent.endTapComponent();
                          widget.policy.onComponentScaleEnd(component.id, details);
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
                      transform: Matrix4.identity()..scale(canvasState.scale),
                      child: _componentBody,
                    ),
                  ),
                  widget.policy.showCustomWidgetWithComponentData(context, component),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
