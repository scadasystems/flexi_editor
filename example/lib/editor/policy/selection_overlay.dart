part of '../example_policy_set.dart';

class _ComponentSelectionOverlay extends StatelessWidget {
  final ExamplePolicySet policy;
  final Component componentData;

  const _ComponentSelectionOverlay({
    required this.policy,
    required this.componentData,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<CanvasState, EditorController>(
      builder: (context, canvasState, controller, child) {
        if (!controller.isComponentSelected(componentData.id)) {
          return const SizedBox.shrink();
        }

        final showHandles =
            controller.tool == EditorTool.select &&
            controller.selectedComponentIds.length == 1;

        final left =
            canvasState.scale * componentData.position.dx +
            canvasState.position.dx;
        final top =
            canvasState.scale * componentData.position.dy +
            canvasState.position.dy;
        final width = canvasState.scale * componentData.size.width;
        final height = canvasState.scale * componentData.size.height;
        const overlayPadding = 28.0;
        final rect = Rect.fromLTWH(
          overlayPadding,
          overlayPadding,
          width,
          height,
        );
        const highlightStrokeWidth = 2.0;
        final data = componentData.data;
        final rotationRadians = data is EditorShapeData ? data.rotationRadians : 0.0;

        return Positioned(
          left: left - overlayPadding,
          top: top - overlayPadding,
          width: width + overlayPadding * 2,
          height: height + overlayPadding * 2,
          child: Transform.rotate(
            angle: rotationRadians,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: rect.left,
                  top: rect.top,
                  width: rect.width,
                  height: rect.height,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: ComponentHighlightPainter(
                        type: ComponentHighlightPainterType.solid,
                        width: width,
                        height: height,
                        color: const Color(0xFF2563EB),
                        strokeWidth: highlightStrokeWidth,
                        showOutRect: true,
                      ),
                    ),
                  ),
                ),
                if (showHandles) ...[
                  _ResizeHandle(
                    policy: policy,
                    canvasState: canvasState,
                    componentData: componentData,
                    type: _ResizeHandleType.topLeft,
                    rect: rect,
                    highlightStrokeWidth: highlightStrokeWidth,
                  ),
                  _ResizeHandle(
                    policy: policy,
                    canvasState: canvasState,
                    componentData: componentData,
                    type: _ResizeHandleType.topRight,
                    rect: rect,
                    highlightStrokeWidth: highlightStrokeWidth,
                  ),
                  _ResizeHandle(
                    policy: policy,
                    canvasState: canvasState,
                    componentData: componentData,
                    type: _ResizeHandleType.bottomLeft,
                    rect: rect,
                    highlightStrokeWidth: highlightStrokeWidth,
                  ),
                  _ResizeHandle(
                    policy: policy,
                    canvasState: canvasState,
                    componentData: componentData,
                    type: _ResizeHandleType.bottomRight,
                    rect: rect,
                    highlightStrokeWidth: highlightStrokeWidth,
                  ),
                  _RotateHandle(
                    policy: policy,
                    canvasState: canvasState,
                    componentData: componentData,
                    rect: rect,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

