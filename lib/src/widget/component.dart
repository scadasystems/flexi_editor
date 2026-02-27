import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/model/port_type.dart';
import 'package:flexi_editor/src/widget/port.dart';
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
                clipBehavior: Clip.none, // 포트가 밖으로 나갈 수 있도록 설정
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: width,
                    height: height,
                    child: Container(
                      child: widget.policy.showComponentBody(component),
                    ),
                  ),
                  widget.policy.showCustomWidgetWithComponentData(
                    context,
                    component,
                  ),
                  // 포트 위젯 추가
                  if (component.showPort) ..._buildPorts(component, width, height),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPorts(
      Component component, double scaledWidth, double scaledHeight) {
    const double portSize = 12.0;
    final List<Widget> ports = [];

    for (final type in PortType.values) {
      if (!component.isPortVisible(type)) continue;

      double? left, top, right, bottom;

      // 포트의 중심이 해당 위치에 오도록 좌표 계산
      // getPortPosition은 컴포넌트의 Border 상의 점을 반환하므로
      // 해당 점을 중심으로 포트를 그리기 위해 portSize / 2 만큼 이동해야 함
      switch (type) {
        case PortType.top:
          left = scaledWidth / 2 - portSize / 2;
          top = -portSize / 2;
          break;
        case PortType.bottom:
          left = scaledWidth / 2 - portSize / 2;
          top = scaledHeight - portSize / 2; // bottom 대신 top 사용으로 통일성 확보
          break;
        case PortType.left:
          top = scaledHeight / 2 - portSize / 2;
          left = -portSize / 2;
          break;
        case PortType.right:
          top = scaledHeight / 2 - portSize / 2;
          left = scaledWidth - portSize / 2; // right 대신 left 사용으로 통일성 확보
          break;
      }

      ports.add(
        Positioned(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          width: portSize,
          height: portSize,
          child: PortWidget(
            componentId: component.id,
            portType: type,
            policy: widget.policy,
            size: portSize,
          ),
        ),
      );
    }

    return ports;
  }
}
