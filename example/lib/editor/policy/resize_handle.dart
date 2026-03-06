part of '../example_policy_set.dart';

enum _ResizeHandleType { topLeft, topRight, bottomLeft, bottomRight }

Offset _rotateVector(Offset vector, double angleRadians) {
  final cosA = math.cos(angleRadians);
  final sinA = math.sin(angleRadians);
  return Offset(
    vector.dx * cosA - vector.dy * sinA,
    vector.dx * sinA + vector.dy * cosA,
  );
}

Offset _rotatePointAround(Offset point, Offset center, double angleRadians) {
  return center + _rotateVector(point - center, angleRadians);
}

class _ResizeHandle extends StatefulWidget {
  final ExamplePolicySet policy;
  final CanvasState canvasState;
  final Component componentData;
  final _ResizeHandleType type;
  final Rect rect;
  final double highlightStrokeWidth;

  static const double _handleSize = 10;
  static const double _minSize = 16;

  const _ResizeHandle({
    required this.policy,
    required this.canvasState,
    required this.componentData,
    required this.type,
    required this.rect,
    required this.highlightStrokeWidth,
  });

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  Offset? _startPointerCanvas;
  Offset? _startDraggedCornerCanvas;
  Offset? _fixedCornerCanvas;
  double? _rotationRadians;
  double? _activeAspectRatio;
  bool _lastShiftPressed = false;

  Offset? _canvasPointFromGlobal(Offset globalPoint) {
    final box =
        widget.canvasState.canvasGlobalKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return null;

    final localPoint = box.globalToLocal(globalPoint);
    return (localPoint - widget.canvasState.position) / widget.canvasState.scale;
  }

  double _clampHalf(double value, double minHalf) {
    final absValue = value.abs();
    if (absValue >= minHalf) return value;
    if (value == 0) return minHalf;
    return value.sign * minHalf;
  }

  Offset _applyAspectAndClamp({
    required Offset vUnrot,
    required double aspectRatio,
    required double minHalf,
  }) {
    final signX = vUnrot.dx < 0 ? -1.0 : 1.0;
    final signY = vUnrot.dy < 0 ? -1.0 : 1.0;

    var absX = vUnrot.dx.abs();
    var absY = vUnrot.dy.abs();

    if (absX == 0 && absY == 0) {
      absX = minHalf;
      absY = minHalf;
    }

    if (absY == 0) {
      absY = absX / aspectRatio;
    }

    if (absX / absY >= aspectRatio) {
      absY = absX / aspectRatio;
    } else {
      absX = absY * aspectRatio;
    }

    absX = math.max(absX, minHalf);
    absY = math.max(absY, minHalf);

    if (absX / absY >= aspectRatio) {
      absY = absX / aspectRatio;
    } else {
      absX = absY * aspectRatio;
    }

    absX = math.max(absX, minHalf);
    absY = math.max(absY, minHalf);

    return Offset(signX * absX, signY * absY);
  }

  ({Offset dragged, Offset fixed}) _rotatedDraggedAndFixedCorners({
    required Offset position,
    required Size size,
    required double rotationRadians,
    required _ResizeHandleType type,
  }) {
    final center = position + size.center(Offset.zero);

    final topLeft = position;
    final topRight = Offset(position.dx + size.width, position.dy);
    final bottomLeft = Offset(position.dx, position.dy + size.height);
    final bottomRight = Offset(
      position.dx + size.width,
      position.dy + size.height,
    );

    final rotatedTopLeft = _rotatePointAround(topLeft, center, rotationRadians);
    final rotatedTopRight = _rotatePointAround(
      topRight,
      center,
      rotationRadians,
    );
    final rotatedBottomLeft = _rotatePointAround(
      bottomLeft,
      center,
      rotationRadians,
    );
    final rotatedBottomRight = _rotatePointAround(
      bottomRight,
      center,
      rotationRadians,
    );

    return switch (type) {
      _ResizeHandleType.topLeft => (
          dragged: rotatedTopLeft,
          fixed: rotatedBottomRight,
        ),
      _ResizeHandleType.topRight => (
          dragged: rotatedTopRight,
          fixed: rotatedBottomLeft,
        ),
      _ResizeHandleType.bottomLeft => (
          dragged: rotatedBottomLeft,
          fixed: rotatedTopRight,
        ),
      _ResizeHandleType.bottomRight => (
          dragged: rotatedBottomRight,
          fixed: rotatedTopLeft,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final half = _ResizeHandle._handleSize / 2;
    final r = widget.highlightStrokeWidth == 0
        ? widget.rect
        : widget.rect.inflate(widget.highlightStrokeWidth / 2);

    final position = switch (widget.type) {
      _ResizeHandleType.topLeft => Offset(r.left - half, r.top - half),
      _ResizeHandleType.topRight => Offset(r.right - half, r.top - half),
      _ResizeHandleType.bottomLeft => Offset(r.left - half, r.bottom - half),
      _ResizeHandleType.bottomRight => Offset(r.right - half, r.bottom - half),
    };

    final cursor = switch (widget.type) {
      _ResizeHandleType.topLeft ||
      _ResizeHandleType.bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
      _ResizeHandleType.topRight ||
      _ResizeHandleType.bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
    };

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: _ResizeHandle._handleSize,
      height: _ResizeHandle._handleSize,
      child: FlexiPointer(
        paintOnTop: true,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              final data = widget.componentData.data;
              final rotationRadians =
                  data is EditorShapeData ? data.rotationRadians : 0.0;
              final startPointerCanvas =
                  _canvasPointFromGlobal(details.globalPosition);
              if (startPointerCanvas == null) return;

              final corners = _rotatedDraggedAndFixedCorners(
                position: widget.componentData.position,
                size: widget.componentData.size,
                rotationRadians: rotationRadians,
                type: widget.type,
              );

              _rotationRadians = rotationRadians;
              _startPointerCanvas = startPointerCanvas;
              _startDraggedCornerCanvas = corners.dragged;
              _fixedCornerCanvas = corners.fixed;
              _lastShiftPressed = HardwareKeyboard.instance.isShiftPressed;
              _activeAspectRatio = widget.componentData.size.height == 0
                  ? null
                  : widget.componentData.size.width / widget.componentData.size.height;
            },
            onPanUpdate: (details) {
              final startPointerCanvas = _startPointerCanvas;
              final startDraggedCornerCanvas = _startDraggedCornerCanvas;
              final fixedCornerCanvas = _fixedCornerCanvas;
              final rotationRadians = _rotationRadians;
              if (startPointerCanvas == null ||
                  startDraggedCornerCanvas == null ||
                  fixedCornerCanvas == null ||
                  rotationRadians == null) {
                return;
              }

              final currentPointerCanvas =
                  _canvasPointFromGlobal(details.globalPosition);
              if (currentPointerCanvas == null) return;

              final shiftPressed = HardwareKeyboard.instance.isShiftPressed;
              if (shiftPressed != _lastShiftPressed) {
                final corners = _rotatedDraggedAndFixedCorners(
                  position: widget.componentData.position,
                  size: widget.componentData.size,
                  rotationRadians: rotationRadians,
                  type: widget.type,
                );
                _startPointerCanvas = currentPointerCanvas;
                _startDraggedCornerCanvas = corners.dragged;
                _fixedCornerCanvas = corners.fixed;
                _lastShiftPressed = shiftPressed;
                _activeAspectRatio = widget.componentData.size.height == 0
                    ? null
                    : widget.componentData.size.width /
                        widget.componentData.size.height;
              }

              final deltaPointer = currentPointerCanvas - startPointerCanvas;
              var draggedCornerCanvas = startDraggedCornerCanvas + deltaPointer;

              final diff = draggedCornerCanvas - fixedCornerCanvas;
              var vRot = diff / 2;
              var vUnrot = _rotateVector(vRot, -rotationRadians);

              final minHalf = _ResizeHandle._minSize / 2;
              final clampedVUnrot = shiftPressed && _activeAspectRatio != null
                  ? _applyAspectAndClamp(
                      vUnrot: vUnrot,
                      aspectRatio: _activeAspectRatio!,
                      minHalf: minHalf,
                    )
                  : Offset(
                      _clampHalf(vUnrot.dx, minHalf),
                      _clampHalf(vUnrot.dy, minHalf),
                    );

              if (clampedVUnrot != vUnrot) {
                vUnrot = clampedVUnrot;
                vRot = _rotateVector(vUnrot, rotationRadians);
                draggedCornerCanvas = fixedCornerCanvas + vRot * 2;
              }

              final center = fixedCornerCanvas + vRot;
              final corner1 = center + vUnrot;
              final corner2 = center - vUnrot;

              final left = math.min(corner1.dx, corner2.dx);
              final top = math.min(corner1.dy, corner2.dy);
              final width = (corner1.dx - corner2.dx).abs();
              final height = (corner1.dy - corner2.dy).abs();

              widget.policy.canvasWriter.model.setComponentPosition(
                widget.componentData.id,
                Offset(left, top),
              );
              widget.policy.canvasWriter.model.setComponentSize(
                widget.componentData.id,
                Size(width, height),
              );
              widget.policy.canvasWriter.model.updateComponentLinks(
                widget.componentData.id,
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
                color: const Color(0xFFFFFFFF),
                border: Border.all(color: const Color(0xFF2563EB), width: 1),
                borderRadius: .circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
