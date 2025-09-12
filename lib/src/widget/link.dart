import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/utils/painter/link_joint_painter.dart';
import 'package:flexi_editor/src/utils/painter/link_painter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Link extends StatelessWidget {
  final PolicySet policy;

  const Link({
    super.key,
    required this.policy,
  });

  @override
  Widget build(BuildContext context) {
    final linkData = Provider.of<LinkData>(context);
    final canvasState = Provider.of<CanvasState>(context);

    LinkPainter linkPainter = LinkPainter(
      linkPoints: (linkData.linkPoints.map(
        (point) => point * canvasState.scale + canvasState.position,
      )).toList(),
      scale: canvasState.scale,
      linkStyle: linkData.linkStyle,
    );

    return Listener(
      onPointerSignal: (PointerSignalEvent event) =>
          policy.onLinkPointerSignal(linkData.id, event),
      child: GestureDetector(
        onTap: () => policy.onLinkTap(linkData.id),
        onTapDown: (details) => policy.onLinkTapDown(linkData.id, details),
        onTapUp: (details) => policy.onLinkTapUp(linkData.id, details),
        onTapCancel: () => policy.onLinkTapCancel(linkData.id),
        onScaleStart: (details) =>
            policy.onLinkScaleStart(linkData.id, details),
        onScaleUpdate: (details) =>
            policy.onLinkScaleUpdate(linkData.id, details),
        onScaleEnd: (details) => policy.onLinkScaleEnd(linkData.id, details),
        onLongPress: () => policy.onLinkLongPress(linkData.id),
        onLongPressStart: (details) =>
            policy.onLinkLongPressStart(linkData.id, details),
        onLongPressMoveUpdate: (details) =>
            policy.onLinkLongPressMoveUpdate(linkData.id, details),
        onLongPressEnd: (details) =>
            policy.onLinkLongPressEnd(linkData.id, details),
        onLongPressUp: () => policy.onLinkLongPressUp(linkData.id),
        child: CustomPaint(
          painter: linkPainter,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ...linkData.linkPoints
                  .getRange(1, linkData.linkPoints.length - 1)
                  .map(
                (jointPoint) {
                  var index = linkData.linkPoints.indexOf(jointPoint);

                  return GestureDetector(
                    onTap: () => policy.onLinkJointTap(index, linkData.id),
                    onTapDown: (details) =>
                        policy.onLinkJointTapDown(index, linkData.id, details),
                    onTapUp: (details) =>
                        policy.onLinkJointTapUp(index, linkData.id, details),
                    onTapCancel: () =>
                        policy.onLinkJointTapCancel(index, linkData.id),
                    onScaleStart: (details) => policy.onLinkJointScaleStart(
                        index, linkData.id, details),
                    onScaleUpdate: (details) => policy.onLinkJointScaleUpdate(
                        index, linkData.id, details),
                    onScaleEnd: (details) =>
                        policy.onLinkJointScaleEnd(index, linkData.id, details),
                    onLongPress: () =>
                        policy.onLinkJointLongPress(index, linkData.id),
                    onLongPressStart: (details) => policy
                        .onLinkJointLongPressStart(index, linkData.id, details),
                    onLongPressMoveUpdate: (details) =>
                        policy.onLinkJointLongPressMoveUpdate(
                            index, linkData.id, details),
                    onLongPressEnd: (details) => policy.onLinkJointLongPressEnd(
                        index, linkData.id, details),
                    onLongPressUp: () =>
                        policy.onLinkJointLongPressUp(index, linkData.id),
                    child: CustomPaint(
                      painter: LinkJointPainter(
                        location: canvasState.toCanvasCoordinates(jointPoint),
                        radius: linkData.linkStyle.lineWidth / 2,
                        scale: canvasState.scale,
                        color: linkData.linkStyle.color,
                      ),
                    ),
                  );
                },
              ),
              ...policy.showWidgetsWithLinkData(context, linkData),
            ],
          ),
        ),
      ),
    );
  }
}
