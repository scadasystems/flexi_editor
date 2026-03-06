part of '../example_policy_set.dart';

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
  State<_RotateHandle> createState() => _RotateHandleState();
}

class _RotateHandleState extends State<_RotateHandle> {
  double? _startPointerAngle;
  double? _startRotationRadians;

  double _angleFromGlobalPoint(Offset globalPoint) {
    final box =
        widget.canvasState.canvasGlobalKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return 0;

    final localPoint = box.globalToLocal(globalPoint);
    final canvasPoint =
        (localPoint - widget.canvasState.position) / widget.canvasState.scale;

    final center =
        widget.componentData.position + widget.componentData.size.center(Offset.zero);
    return math.atan2(canvasPoint.dy - center.dy, canvasPoint.dx - center.dx);
  }

  double _normalizeDelta(double delta) {
    const tau = math.pi * 2;
    var normalized = delta % tau;
    if (normalized > math.pi) normalized -= tau;
    if (normalized <= -math.pi) normalized += tau;
    return normalized;
  }

  @override
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
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                border: Border.all(color: const Color(0xFF2563EB), width: 1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

