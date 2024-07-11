// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/utils/painter/selection_box_painter.dart';
import 'package:flexi_editor/src/widget/component.dart';
import 'package:flexi_editor/src/widget/link.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef SelectionRectChangedCallback = Function(Rect selectionRect);
typedef KeyboardEventCallback = Function(KeyEvent keyEvent);

class FlexiEditorCanvas extends StatefulWidget {
  final PolicySet policy;
  final VoidCallback? onSelectionRectStart;
  final SelectionRectChangedCallback? onSelectionRectUpdate;
  final VoidCallback? onSelectionRectEnd;
  final KeyboardEventCallback? onKeyboardEvent;

  /// - [policy]: 캔버스 정책
  /// - [onSelectionRectChanged]: 선택 영역 변경 이벤트
  const FlexiEditorCanvas({
    super.key,
    required this.policy,
    this.onSelectionRectStart,
    this.onSelectionRectUpdate,
    this.onSelectionRectEnd,
    this.onKeyboardEvent,
  });

  @override
  FlexiEditorCanvasState createState() => FlexiEditorCanvasState();
}

class FlexiEditorCanvasState extends State<FlexiEditorCanvas> with TickerProviderStateMixin {
  PolicySet? withControlPolicy;

  @override
  void initState() {
    withControlPolicy = (widget.policy is CanvasControlPolicy) || (widget.policy is CanvasMovePolicy) //
        ? widget.policy
        : null;

    (withControlPolicy as CanvasControlPolicy?)?.setAnimationController(
      AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    (withControlPolicy as CanvasControlPolicy?)?.disposeAnimationController();
    super.dispose();
  }

  List<Widget> showComponents(CanvasModel canvasModel) {
    var zOrderedComponents = canvasModel.components.values.toList();
    zOrderedComponents.sort((a, b) => a.zOrder.compareTo(b.zOrder));

    return zOrderedComponents
        .map(
          (componentData) => ChangeNotifierProvider<ComponentData>.value(
            value: componentData,
            child: Component(
              policy: widget.policy,
            ),
          ),
        )
        .toList();
  }

  List<Widget> showLinks(CanvasModel canvasModel) {
    return canvasModel.links.values.map((LinkData linkData) {
      return ChangeNotifierProvider<LinkData>.value(
        value: linkData,
        child: Link(
          policy: widget.policy,
        ),
      );
    }).toList();
  }

  List<Widget> showOtherWithComponentDataUnder(CanvasModel canvasModel) {
    return canvasModel.components.values.map((ComponentData componentData) {
      return ChangeNotifierProvider<ComponentData>.value(
        value: componentData,
        builder: (context, child) {
          return Consumer<ComponentData>(
            builder: (context, data, child) {
              return widget.policy.showCustomWidgetWithComponentDataUnder(context, data);
            },
          );
        },
      );
    }).toList();
  }

  List<Widget> showOtherWithComponentDataOver(CanvasModel canvasModel) {
    return canvasModel.components.values.map((ComponentData componentData) {
      return ChangeNotifierProvider<ComponentData>.value(
        value: componentData,
        builder: (context, child) {
          return Consumer<ComponentData>(
            builder: (context, data, child) {
              return widget.policy.showCustomWidgetWithComponentDataOver(context, data);
            },
          );
        },
      );
    }).toList();
  }

  List<Widget> showBackgroundWidgets() {
    return widget.policy.showCustomWidgetsOnCanvasBackground(context);
  }

  List<Widget> showForegroundWidgets() {
    return widget.policy.showCustomWidgetsOnCanvasForeground(context);
  }

  Widget canvasStack(CanvasModel canvasModel) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        ...showBackgroundWidgets(),
        ...showOtherWithComponentDataUnder(canvasModel),
        if (widget.policy.showLinksOnTopOfComponents) ...showComponents(canvasModel),
        ...showLinks(canvasModel),
        if (!widget.policy.showLinksOnTopOfComponents) ...showComponents(canvasModel),
        ...showOtherWithComponentDataOver(canvasModel),
        ...showForegroundWidgets(),
      ],
    );
  }

  Widget canvasAnimated(CanvasModel canvasModel) {
    final animationController = (withControlPolicy as CanvasControlPolicy).getAnimationController();
    if (animationController == null) return canvasStack(canvasModel);

    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
        (withControlPolicy as CanvasControlPolicy).canUpdateCanvasModel = true;
        return Transform(
          transform: Matrix4.identity()
            ..translate(
              (withControlPolicy as CanvasControlPolicy).transformPosition.dx,
              (withControlPolicy as CanvasControlPolicy).transformPosition.dy,
            )
            ..scale((withControlPolicy as CanvasControlPolicy).transformScale),
          child: child,
        );
      },
      child: canvasStack(canvasModel),
    );
  }

  /// 캔버스
  Widget _buildGestureDetector(BuildContext context) {
    return Consumer3<CanvasModel, CanvasState, CanvasEvent>(
      builder: (context, canvaseModel, canvasState, canvasEvent, child) {
        return GestureDetector(
          onScaleStart: (details) {
            widget.onSelectionRectStart?.call();

            if (canvasEvent.isStartDragSelection) {
              canvasEvent.startSelectDragPosition(details);
            } else {
              widget.policy.onCanvasScaleStartEvent(details);
            }
          },
          onScaleUpdate: (details) {
            if (canvasEvent.isStartDragSelection) {
              canvasEvent.updateSelectDragPosition(details);
            } else {
              widget.policy.onCanvasScaleUpdateEvent(details);
            }
          },
          onScaleEnd: (details) {
            widget.onSelectionRectEnd?.call();

            if (canvasEvent.isStartDragSelection) {
              canvasEvent.endSelectDragPosition();
            } else {
              widget.policy.onCanvasScaleEndEvent(details);
            }
          },
          onTap: widget.policy.onCanvasTap,
          onTapDown: widget.policy.onCanvasTapDown,
          onTapUp: widget.policy.onCanvasTapUp,
          onTapCancel: widget.policy.onCanvasTapCancel,
          onLongPress: widget.policy.onCanvasLongPress,
          onLongPressStart: widget.policy.onCanvasLongPressStart,
          onLongPressMoveUpdate: widget.policy.onCanvasLongPressMoveUpdate,
          onLongPressEnd: widget.policy.onCanvasLongPressEnd,
          onLongPressUp: widget.policy.onCanvasLongPressUp,
          child: Container(
            color: canvasState.color,
            child: ClipRect(
              child: (withControlPolicy != null)
                  ? canvasAnimated(context.read<CanvasModel>())
                  : canvasStack(context.read<CanvasModel>()),
            ),
          ),
        );
      },
    );
  }

  /// 선택 드래그 영역
  Widget _buildSelectionBox(BuildContext context) {
    final canvasState = context.read<CanvasState>();

    return Consumer2<CanvasEvent, CanvasModel>(
      builder: (context, canvasEvent, canvasModel, child) {
        if (canvasEvent.startDragPosition != null && //
            canvasEvent.currentDragPosition != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final scale = canvasState.scale;
            final position = canvasState.position;

            final selectionRect = Rect.fromPoints(
              (canvasEvent.startDragPosition! - position) / scale,
              (canvasEvent.currentDragPosition! - position) / scale,
            );

            widget.onSelectionRectUpdate?.call(selectionRect);
          });

          return Positioned.fill(
            child: CustomPaint(
              painter: SelectionBoxPainter(
                startPosition: canvasEvent.startDragPosition!,
                endPosition: canvasEvent.currentDragPosition!,
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// 스페이스 누를 때 마우스 커서
  Widget _buildGrabbingArea(BuildContext context) {
    return Consumer<CanvasEvent>(
      builder: (context, canvasEvent, child) {
        if (canvasEvent.isSpacePressed) {
          return Positioned.fill(
            child: MouseRegion(
              cursor: canvasEvent.mouseCursor,
              child: GestureDetector(
                onScaleStart: (details) {
                  canvasEvent.setMouseGrabCursor(true);
                  widget.policy.onCanvasScaleStart(details);
                },
                onScaleUpdate: widget.policy.onCanvasScaleUpdate,
                onScaleEnd: (details) {
                  canvasEvent.setMouseGrabCursor(false);
                  widget.policy.onCanvasScaleEnd(details);
                },
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => context.read<CanvasEvent>().requestFocus(),
      onExit: (event) => context.read<CanvasEvent>().unfocus(),
      child: Focus(
        focusNode: context.read<CanvasEvent>().keyboardFocusNode,
        onKeyEvent: context.read<CanvasEvent>().onKeyboardEvent,
        child: AbsorbPointer(
          absorbing: context.read<CanvasState>().shouldAbsorbPointer,
          child: Listener(
            onPointerSignal: widget.policy.onCanvasPointerSignal,
            child: Stack(
              children: [
                _buildGestureDetector(context),
                _buildSelectionBox(context),
                _buildGrabbingArea(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
