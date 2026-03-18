part of '../example_policy_set.dart';

/// 선택 컴포넌트의 회전 조절 핸들 위젯입니다.
class _RotateHandle extends StatefulWidget {
  final ExamplePolicySet policy;
  final CanvasState canvasState;
  final Component componentData;
  final Rect rect;

  static const double _handleDiameter = 12;
  static const double _handleOffset = 18;

  const _RotateHandle({
    required this.policy,
    required this.canvasState,
    required this.componentData,
    required this.rect,
  });

  @override
  /// 회전 핸들의 상태를 생성합니다.
  State<_RotateHandle> createState() => _RotateHandleState();
}

class _RotateHandleState extends State<_RotateHandle> {
  double? _startPointerAngle;
  double? _startRotationRadians;

  /// 글로벌 좌표에서 컴포넌트 중심을 기준으로 한 각도를 계산합니다.
  double _angleFromGlobalPoint(Offset globalPoint) {
    final box =
        widget.canvasState.canvasGlobalKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return 0;

    final localPoint = box.globalToLocal(globalPoint);
    final canvasPoint =
        (localPoint - widget.canvasState.position) / widget.canvasState.scale;

    final worldPosition = widget.policy.canvasReader.model
        .getComponentWorldPosition(widget.componentData.id);
    final center = worldPosition + widget.componentData.size.center(Offset.zero);
    return math.atan2(canvasPoint.dy - center.dy, canvasPoint.dx - center.dx);
  }

  /// 델타 각도를 [-pi, pi] 범위로 정규화합니다.
  double _normalizeDelta(double delta) {
    const tau = math.pi * 2;
    var normalized = delta % tau;
    if (normalized > math.pi) normalized -= tau;
    if (normalized <= -math.pi) normalized += tau;
    return normalized;
  }

  @override
  /// 회전 핸들의 위치/제스처를 구성하고 드래그로 회전을 업데이트합니다.
  Widget build(BuildContext context) {
    final left =
        widget.rect.left + widget.rect.width / 2 - _RotateHandle._handleDiameter / 2;
    final top =
        widget.rect.top -
        _RotateHandle._handleOffset -
        _RotateHandle._handleDiameter / 2;

    return Positioned(
      left: left,
      top: top,
      width: _RotateHandle._handleDiameter,
      height: _RotateHandle._handleDiameter,
      child: FlexiPointer(
        paintOnTop: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              final data = widget.componentData.data;
              final shapeData = data is EditorShapeData
                  ? data
                  : const EditorShapeData(
                      fillColorValue: 0xFFFFFFFF,
                      strokeColorValue: 0xFF111827,
                      strokeWidth: 1,
                      cornerRadius: 8,
                      rotationRadians: 0,
                    );

              _startRotationRadians = shapeData.rotationRadians;
              _startPointerAngle = _angleFromGlobalPoint(details.globalPosition);
            },
            onPanUpdate: (details) {
              final startPointerAngle = _startPointerAngle;
              final startRotationRadians = _startRotationRadians;
              if (startPointerAngle == null || startRotationRadians == null) {
                return;
              }

              final currentPointerAngle = _angleFromGlobalPoint(details.globalPosition);
              final delta =
                  _normalizeDelta(currentPointerAngle - startPointerAngle);
              var angle = startRotationRadians + delta;

              if (HardwareKeyboard.instance.isShiftPressed) {
                const step = math.pi / 4;
                angle = (angle / step).round() * step;
              }

              final data = widget.componentData.data;
              final shapeData = data is EditorShapeData
                  ? data
                  : const EditorShapeData(
                      fillColorValue: 0xFFFFFFFF,
                      strokeColorValue: 0xFF111827,
                      strokeWidth: 1,
                      cornerRadius: 8,
                      rotationRadians: 0,
                    );

              widget.componentData.updateData(
                shapeData.copyWith(rotationRadians: angle),
              );
            },
            onPanEnd: (details) {
              widget.policy.undoRedoController.commit(
                reader: widget.policy.canvasReader,
              );
            },
            onPanCancel: () {
              widget.policy.undoRedoController.commit(
                reader: widget.policy.canvasReader,
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.policy.uiHandleFillColor,
                border: Border.all(color: widget.policy.uiAccentColor, width: 1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
