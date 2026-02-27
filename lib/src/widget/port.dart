import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/model/connection.dart';
import 'package:flexi_editor/src/canvas_context/model/port_type.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PortWidget extends StatefulWidget {
  final String componentId;
  final PortType portType;
  final PolicySet policy;
  final double size;

  const PortWidget({
    super.key,
    required this.componentId,
    required this.portType,
    required this.policy,
    this.size = 12.0,
  });

  @override
  State<PortWidget> createState() => _PortWidgetState();
}

class _PortWidgetState extends State<PortWidget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final canvasEvent = context.watch<CanvasEvent>();
    final canvasModel = context.read<CanvasModel>();

    // 드래그 중일 때 자신은 스냅 대상에서 제외 (선택적)
    // 현재는 모든 포트를 활성화

    return FlexiPointer(
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovering = true);
          canvasEvent.setHoveringPort(widget.componentId, widget.portType);
        },
        onExit: (_) {
          setState(() => _isHovering = false);
          if (canvasEvent.hoveringPort?.componentId == widget.componentId &&
              canvasEvent.hoveringPort?.portType == widget.portType) {
            canvasEvent.setHoveringPort(null, null);
          }
        },
        child: GestureDetector(
          onPanStart: (details) {
            final canvasEvent = context.read<CanvasEvent>();
            // 현재 컴포넌트의 위치와 크기를 가져옴
            final component = canvasModel.getComponent(widget.componentId);

            // 포트의 상대 위치 계산 (컴포넌트 중심 기준)
            Offset portOffset;
            switch (widget.portType) {
              case PortType.top:
                portOffset = Offset(component.size.width / 2, 0);
                break;
              case PortType.bottom:
                portOffset = Offset(
                  component.size.width / 2,
                  component.size.height,
                );
                break;
              case PortType.left:
                portOffset = Offset(0, component.size.height / 2);
                break;
              case PortType.right:
                portOffset = Offset(
                  component.size.width,
                  component.size.height / 2,
                );
                break;
            }

            // 컴포넌트 위치 + 포트 상대 위치 = 포트의 절대 위치 (Canvas Coordinates)
            final portCenter = component.position + portOffset;

            canvasEvent.startDragConnection(
              widget.componentId,
              widget.portType,
              portCenter,
            );
          },
          onPanUpdate: (details) {
            final canvasEvent = context.read<CanvasEvent>();
            final canvasState = context.read<CanvasState>();
            final canvasPos =
                (details.globalPosition - canvasState.position) /
                canvasState.scale;
            canvasEvent.updateDragConnection(canvasPos);

            // 스냅 로직: 다른 포트들과 거리 계산
            _checkSnap(canvasModel, canvasPos);
          },
          onPanEnd: (details) {
            final canvasEvent = context.read<CanvasEvent>();
            final snapped = canvasEvent.snappedPort;
            final hovering = canvasEvent.hoveringPort;

            // 스냅된 포트가 있거나, 현재 마우스가 호버 중인 포트가 있다면 연결 시도
            // 스냅된 포트를 우선시함
            final target = snapped ?? hovering;

            if (target != null) {
              final sourceId = canvasEvent.draggingSourceComponentId;
              final sourcePort = canvasEvent.draggingSourcePort;
              final targetId = target.componentId;
              final targetPort = target.portType;

              if (sourceId != null && sourcePort != null) {
                // 자기 자신과의 연결 체크 (선택 사항)
                if (sourceId == targetId) {
                  canvasEvent.stopDragConnection();
                  return;
                }

                // 정책 확인 및 연결 생성
                if (widget.policy.canCreateLink(
                  sourceId,
                  sourcePort,
                  targetId,
                  targetPort,
                )) {
                  final connection = Connection(
                    sourceComponentId: sourceId,
                    sourcePort: sourcePort,
                    targetComponentId: targetId,
                    targetPort: targetPort,
                  );
                  canvasModel.addConnection(connection);
                  widget.policy.onLinkCreated(sourceId, targetId);
                }
              }
            }
            canvasEvent.stopDragConnection();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isHovering ? widget.size * 1.5 : widget.size,
            height: _isHovering ? widget.size * 1.5 : widget.size,
            decoration: BoxDecoration(
              color: _isHovering ? Colors.blueAccent : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blueAccent,
                width: 2.0,
              ),
              boxShadow: _isHovering
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  void _checkSnap(CanvasModel canvasModel, Offset currentPos) {
    const double snapDistance = 20.0;
    // 제곱근 연산을 피하기 위해 거리의 제곱을 비교
    const double snapDistanceSquared = snapDistance * snapDistance;
    
    PortInfo? closestPort;
    double minDistanceSquared = double.infinity;

    for (final component in canvasModel.components.values) {
      // 자신과의 연결은 제외 (필요에 따라 허용 가능)
      if (component.id == widget.componentId) continue;

      // 포트가 숨겨져 있으면 스냅 제외
      if (!component.showPort) continue;

      for (final type in PortType.values) {
        if (!component.isPortVisible(type)) continue;

        final portPos = component.getPortPosition(type);
        final distanceSquared = (portPos - currentPos).distanceSquared;

        if (distanceSquared < snapDistanceSquared && distanceSquared < minDistanceSquared) {
          minDistanceSquared = distanceSquared;
          closestPort = PortInfo(component.id, type);
        }
      }
    }

    final canvasEvent = context.read<CanvasEvent>();
    if (closestPort != null) {
      canvasEvent.setSnappedPort(closestPort.componentId, closestPort.portType);
    } else {
      // 이미 스냅된 상태가 아니었을 때만 null로 설정하여 불필요한 업데이트 방지
      // (단, 여기서는 매번 최단 거리를 계산하므로 항상 업데이트해야 정확함)
      canvasEvent.setSnappedPort(null, null);
    }
  }
}
