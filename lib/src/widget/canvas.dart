import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/canvas_state.dart';
import 'package:flexi_editor/src/widget/component.dart';
import 'package:flexi_editor/src/widget/link.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class FlexiEditorCanvas extends StatefulWidget {
  final PolicySet policy;

  const FlexiEditorCanvas({
    super.key,
    required this.policy,
  });

  @override
  FlexiEditorCanvasState createState() => FlexiEditorCanvasState();
}

class FlexiEditorCanvasState extends State<FlexiEditorCanvas>
    with TickerProviderStateMixin {
  PolicySet? withControlPolicy;
  final _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    withControlPolicy = //
        widget.policy is CanvasControlPolicy ||
                widget.policy is CanvasMovePolicy
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
    _keyboardFocusNode.dispose();
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
              return widget.policy
                  .showCustomWidgetWithComponentDataUnder(context, data);
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
              return widget.policy
                  .showCustomWidgetWithComponentDataOver(context, data);
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
        if (widget.policy.showLinksOnTopOfComponents)
          ...showComponents(canvasModel),
        ...showLinks(canvasModel),
        if (!widget.policy.showLinksOnTopOfComponents)
          ...showComponents(canvasModel),
        ...showOtherWithComponentDataOver(canvasModel),
        ...showForegroundWidgets(),
      ],
    );
  }

  Widget canvasAnimated(CanvasModel canvasModel) {
    final animationController =
        (withControlPolicy as CanvasControlPolicy).getAnimationController();
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

  KeyEventResult _onKeyboardEvent(FocusNode node, KeyEvent event) {
    final isControlPressed = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (isControlPressed &&
        HardwareKeyboard.instance.isLogicalKeyPressed(event.logicalKey)) {
      if (event is KeyDownEvent) {
        print('Control + ${event.logicalKey.keyLabel}');
      }
    }

    // if (HardwareKeyboard.instance.isControlPressed ||
    //     HardwareKeyboard.instance.isShiftPressed ||
    //     HardwareKeyboard.instance.isAltPressed ||
    //     HardwareKeyboard.instance.isMetaPressed) {
    //   print('Modifier pressed: $event');
    // }
    // if (HardwareKeyboard.instance
    //     .isLogicalKeyPressed(LogicalKeyboardKey.keyA)) {
    //   print('Key A pressed.');
    // }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final canvasModel = Provider.of<CanvasModel>(context);
    final canvasState = Provider.of<CanvasState>(context);

    return MouseRegion(
      onEnter: (event) => _keyboardFocusNode.requestFocus(),
      onExit: (event) => _keyboardFocusNode.unfocus(),
      child: Focus(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _onKeyboardEvent,
        child: RepaintBoundary(
          key: canvasState.canvasGlobalKey,
          child: AbsorbPointer(
            absorbing: canvasState.shouldAbsorbPointer,
            child: Listener(
              onPointerSignal: (PointerSignalEvent event) =>
                  widget.policy.onCanvasPointerSignal(event),
              child: GestureDetector(
                onScaleStart: (details) =>
                    widget.policy.onCanvasScaleStart(details),
                onScaleUpdate: (details) =>
                    widget.policy.onCanvasScaleUpdate(details),
                onScaleEnd: (details) =>
                    widget.policy.onCanvasScaleEnd(details),
                onTap: () => widget.policy.onCanvasTap(),
                onTapDown: (TapDownDetails details) =>
                    widget.policy.onCanvasTapDown(details),
                onTapUp: (TapUpDetails details) =>
                    widget.policy.onCanvasTapUp(details),
                onTapCancel: () => widget.policy.onCanvasTapCancel(),
                onLongPress: () => widget.policy.onCanvasLongPress(),
                onLongPressStart: (LongPressStartDetails details) =>
                    widget.policy.onCanvasLongPressStart(details),
                onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) =>
                    widget.policy.onCanvasLongPressMoveUpdate(details),
                onLongPressEnd: (LongPressEndDetails details) =>
                    widget.policy.onCanvasLongPressEnd(details),
                onLongPressUp: () => widget.policy.onCanvasLongPressUp(),
                child: Container(
                  color: canvasState.color,
                  child: ClipRect(
                    child: (withControlPolicy != null)
                        ? canvasAnimated(canvasModel)
                        : canvasStack(canvasModel),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
