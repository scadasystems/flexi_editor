// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/canvas_context/model/port_type.dart';
import 'package:flexi_editor/src/utils/painter/connection_painter.dart';
import 'package:flexi_editor/src/utils/painter/grid_painter.dart';
import 'package:flexi_editor/src/utils/painter/selection_box_painter.dart';
import 'package:flexi_editor/src/widget/component.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

typedef SelectionRectChangedCallback = Function(Rect selectionRect);
typedef KeyboardEventCallback = Function(FocusNode node, KeyEvent keyEvent);

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

class FlexiEditorCanvasState extends State<FlexiEditorCanvas>
    with TickerProviderStateMixin {
  late PolicySet withControlPolicy;

  // Pinch 상태 추적을 위한 변수들
  bool _isPinchActive = false;
  int _activePointers = 0;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();

    withControlPolicy = widget.policy;

    (withControlPolicy as CanvasControlPolicy?)?.setAnimationController(
      AnimationController(
        duration: _animationDuration,
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    (withControlPolicy as CanvasControlPolicy?)?.disposeAnimationController();
    super.dispose();
  }

  List<Widget> showComponents(CanvasModel canvasModel) {
    final currentComponents = canvasModel.components.values.toList();
    currentComponents.sort((a, b) => a.zOrder.compareTo(b.zOrder));

    return currentComponents
        .map(
          (e) => ChangeNotifierProvider<Component>.value(
            value: e,
            key: ValueKey(e.id),
            child: ComponentWidget(
              policy: widget.policy,
            ),
          ),
        )
        .toList();
  }

  List<Widget> showOtherWithComponentDataUnder(CanvasModel canvasModel) {
    return canvasModel.components.values.map((Component componentData) {
      return ChangeNotifierProvider.value(
        value: componentData,
        builder: (context, child) {
          return Consumer<Component>(
            key: ValueKey('under_${componentData.id}'),
            builder: (context, value, child) {
              return widget.policy.showCustomWidgetWithComponentDataUnder(
                context,
                componentData,
              );
            },
          );
        },
      );
    }).toList();
  }

  List<Widget> buildComponentOverWidget(CanvasModel canvasModel) {
    return canvasModel.components.values.map((Component componentData) {
      return ChangeNotifierProvider.value(
        value: componentData,
        builder: (context, child) {
          return Consumer<Component>(
            key: ValueKey('over_${componentData.id}'),
            builder: (context, value, child) {
              return widget.policy.buildComponentOverWidget(context, value);
            },
          );
        },
      );
    }).toList();
  }

  List<Widget> buildLinkOverWidget(CanvasModel canvasModel) {
    return canvasModel.components.values.map((Component componentData) {
      return ChangeNotifierProvider.value(
        value: componentData,
        builder: (context, child) {
          return Consumer<Component>(
            key: ValueKey('link_over_${componentData.id}'),
            builder: (context, data, child) {
              return widget.policy.buildLinkOverWidget(context, data);
            },
          );
        },
      );
    }).toList();
  }

  /// 캔버스
  Widget _buildCanvas(BuildContext context) {
    final canvasEvent = context.read<CanvasEvent>();
    final canvasState = context.read<CanvasState>();

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

          final start = canvasEvent.startDragPosition;
          final current = canvasEvent.currentDragPosition;
          if (start != null && current != null) {
            final scale = canvasState.scale;
            final position = canvasState.position;
            final selectionRect = Rect.fromPoints(
              (start - position) / scale,
              (current - position) / scale,
            );
            widget.onSelectionRectUpdate?.call(selectionRect);
          }
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
      child: Container(color: canvasState.color, child: canvasAnimated()),
    );
  }

  Widget canvasAnimated() {
    final animationController = (withControlPolicy as CanvasControlPolicy)
        .getAnimationController();
    if (animationController == null) return canvasStack();

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        (withControlPolicy as CanvasControlPolicy).canUpdateCanvasModel = true;
        return Transform(
          transform:
              Matrix4.translationValues(
                (withControlPolicy as CanvasControlPolicy).transformPosition.dx,
                (withControlPolicy as CanvasControlPolicy).transformPosition.dy,
                0.0,
              )..multiply(
                Matrix4.diagonal3Values(
                  (withControlPolicy as CanvasControlPolicy).transformScale,
                  (withControlPolicy as CanvasControlPolicy).transformScale,
                  1.0,
                ),
              ),
          child: child,
        );
      },
      child: canvasStack(),
    );
  }

  Widget canvasStack() {
    return DeferredPointerHandler(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CustomBackgroundWidgetsLayer(policy: widget.policy),
          _GridLayer(), // 그리드 레이어
          _ConnectionsLayer(), // 연결선 레이어 (다시 컴포넌트 아래로 이동)
          Selector<CanvasEvent, bool>(
            selector: (_, event) => event.isTapComponent,
            builder: (context, isTapComponent, _) {
              return _buildCanvasClickable(context, isTapComponent);
            },
          ),
          _ComponentsLayer(policy: widget.policy),
          _ComponentOverWidgetsLayer(policy: widget.policy),
          _CustomForegroundWidgetsLayer(policy: widget.policy),
        ],
      ),
    );
  }

  /// 캔버스 클릭 영역
  Widget _buildCanvasClickable(BuildContext context, bool isTapComponent) {
    return GestureDetector(
      onTap: isTapComponent ? null : widget.policy.onCanvasTap,
      onTapDown: isTapComponent ? null : widget.policy.onCanvasTapDown,
      onTapUp: isTapComponent ? null : widget.policy.onCanvasTapUp,
      onTapCancel: isTapComponent ? null : widget.policy.onCanvasTapCancel,
    );
  }

  /// 선택 드래그 영역
  Widget _buildSelectionBox(BuildContext context) {
    return Consumer2<CanvasEvent, CanvasModel>(
      builder: (context, canvasEvent, canvasModel, child) {
        // 연결선 드래그 중에는 선택 영역 표시하지 않음
        if (canvasEvent.isDragConnection) {
          return const SizedBox.shrink();
        }

        if (canvasEvent.startDragPosition != null &&
            canvasEvent.currentDragPosition != null) {
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
  bool _isDragging = false;
  Widget _buildGrabbingArea(BuildContext context) {
    return Consumer<CanvasEvent>(
      builder: (context, canvasEvent, child) {
        if (canvasEvent.isSpacePressed) {
          return MouseRegion(
            cursor: canvasEvent.mouseCursor,
            child: GestureDetector(
              onPanStart: (details) {
                canvasEvent.setMouseGrabCursor(true);
                _isDragging = true;
                widget.policy.onCanvasScaleStart(
                  ScaleStartDetails(
                    focalPoint: details.localPosition,
                    pointerCount: 1,
                  ),
                );
              },
              onPanUpdate: (details) {
                if (_isDragging) {
                  widget.policy.onCanvasScaleUpdate(
                    ScaleUpdateDetails(
                      focalPoint: details.localPosition,
                      focalPointDelta: details.delta,
                      scale: 1.0,
                    ),
                  );
                }
              },
              onPanEnd: (details) => _endDrag(),
              onPanCancel: () => _endDrag(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _endDrag() {
    if (_isDragging) {
      _isDragging = false;
      widget.policy.onCanvasScaleEnd(ScaleEndDetails());
      context.read<CanvasEvent>().setMouseGrabCursor(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasEvent = context.read<CanvasEvent>();
    final canvasState = context.read<CanvasState>();

    return Focus(
      focusNode: canvasEvent.keyboardFocusNode,
      onKeyEvent: (node, event) {
        if (canvasEvent.disableKeyboardEvents) return KeyEventResult.ignored;

        widget.onKeyboardEvent?.call(node, event);

        //#region 스페이스바 이벤트
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (event is KeyDownEvent) {
            canvasEvent.setSpacePressed(true);
          } else if (event is KeyUpEvent) {
            canvasEvent.setSpacePressed(false);
            _endDrag();
          }

          return KeyEventResult.handled;
        }
        //#endregion

        return KeyEventResult.ignored;
      },
      child: RepaintBoundary(
        key: canvasState.canvasGlobalKey,
        child: MouseRegion(
          onEnter: (event) {
            if (canvasEvent.disableKeyboardEvents) return;
            canvasEvent.requestFocus();
          },
          onExit: (event) {
            if (canvasEvent.disableKeyboardEvents) return;
            canvasEvent.unfocus();
          },
          child: Listener(
            onPointerDown: (event) {
              _activePointers++;
              // 두 개의 포인터가 감지되면 pinch 시작으로 간주
              if (_activePointers == 2) {
                _isPinchActive = true;
              }
            },
            onPointerUp: (event) {
              _activePointers--;
              // 포인터가 2개 미만이 되면 pinch 종료
              if (_activePointers < 2 && _isPinchActive) {
                _isPinchActive = false;
              }
            },
            onPointerPanZoomStart: (event) {
              _isPinchActive = true;
            },
            onPointerPanZoomEnd: (event) {
              if (_isPinchActive) {
                _isPinchActive = false;
              }
            },
            onPointerSignal: (event) {
              // PointerScrollEvent는 CanvasControlPolicy의 onCanvasPointerSignal에서 직접 처리
              if (event is PointerScrollEvent) {
                widget.policy.onCanvasPointerSignal(event);
                return;
              }
              // Scale 이벤트는 pinch/zoom 으로 처리
              else if (event.runtimeType.toString().contains('Scale')) {
                // Scale 이벤트를 정책으로 전달 (onCanvasPointerSignal에서 처리)
                widget.policy.onCanvasPointerSignal(event);
                return;
              }

              // 다른 이벤트들도 정책으로 전달
              widget.policy.onCanvasPointerSignal(event);
            },
            child: Stack(
              children: [
                _buildCanvas(context),
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

class _ComponentsLayer extends StatelessWidget {
  final PolicySet policy;

  const _ComponentsLayer({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Selector<CanvasModel, List<String>>(
      selector: (_, model) {
        final currentComponents = model.components.values.toList();
        currentComponents.sort((a, b) => a.zOrder.compareTo(b.zOrder));
        return currentComponents.map((e) => e.id).toList();
      },
      shouldRebuild: (previous, next) => !listEquals(previous, next),
      builder: (context, componentIds, _) {
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: componentIds.map((id) {
            return Selector<CanvasModel, Component>(
              key: ValueKey(id),
              selector: (_, model) => model.getComponent(id),
              builder: (context, component, _) {
                return ChangeNotifierProvider<Component>.value(
                  value: component,
                  child: ComponentWidget(policy: policy),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _ComponentOverWidgetsLayer extends StatelessWidget {
  final PolicySet policy;

  const _ComponentOverWidgetsLayer({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Selector<CanvasModel, List<String>>(
      selector: (_, model) => model.components.keys.toList(),
      shouldRebuild: (previous, next) => !listEquals(previous, next),
      builder: (context, componentIds, _) {
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: componentIds.map((id) {
            return Selector<CanvasModel, Component>(
              key: ValueKey('over_$id'),
              selector: (_, model) => model.getComponent(id),
              builder: (context, component, _) {
                return ChangeNotifierProvider<Component>.value(
                  value: component,
                  child: Consumer2<Component, CanvasState>(
                    builder: (context, component, canvasState, child) {
                      final left =
                          canvasState.scale * component.position.dx +
                          canvasState.position.dx;
                      final top =
                          canvasState.scale * component.position.dy +
                          canvasState.position.dy;
                      final width = canvasState.scale * component.size.width;
                      final height = canvasState.scale * component.size.height;

                      return Positioned(
                        left: left,
                        top: top,
                        width: width,
                        height: height,
                        child: policy.buildComponentOverWidget(
                          context,
                          component,
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _CustomBackgroundWidgetsLayer extends StatelessWidget {
  final PolicySet policy;

  const _CustomBackgroundWidgetsLayer({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: policy.showCustomWidgetsOnCanvasBackground(context),
    );
  }
}

class _CustomForegroundWidgetsLayer extends StatelessWidget {
  final PolicySet policy;

  const _CustomForegroundWidgetsLayer({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: policy.showCustomWidgetsOnCanvasForeground(context),
    );
  }
}

class _GridLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<CanvasModel, CanvasState>(
      builder: (context, canvasModel, canvasState, child) {
        return CustomPaint(
          painter: GridPainter(
            gridType: canvasModel.gridType,
            gridColor: canvasModel.gridColor,
            gridSpacing: canvasModel.gridSpacing,
            position: canvasState.position,
            scale: canvasState.scale,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _ConnectionsLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer3<CanvasModel, CanvasEvent, CanvasState>(
      builder: (context, canvasModel, canvasEvent, canvasState, child) {
        String? snappedPortComponentId;
        PortType? snappedPortType;

        if (canvasEvent.snappedPort != null) {
          snappedPortComponentId = canvasEvent.snappedPort!.componentId;
          snappedPortType = canvasEvent.snappedPort!.portType;
        }

        return CustomPaint(
          painter: ConnectionPainter(
            connections: canvasModel.connections.values.toList(),
            components: canvasModel.components,
            dragStart: canvasEvent.startDragPosition,
            dragEnd: canvasEvent.currentDragPosition,
            dragSourceComponentId: canvasEvent.draggingSourceComponentId,
            dragSourcePort: canvasEvent.draggingSourcePort,
            snappedPortComponentId: snappedPortComponentId,
            snappedPortType: snappedPortType,
            // CanvasState의 변경사항(scale, position)이 발생하면 다시 그려야 하므로
            // Consumer에 CanvasState를 추가하고, Painter에 전달하거나 의존성을 만듭니다.
            // 여기서는 Painter 내부에서 scale을 사용하지 않더라도,
            // CanvasState가 변경될 때마다 rebuild되어야 하므로 Consumer3를 사용합니다.
            // 필요하다면 Painter에 scale 정보를 전달할 수도 있습니다.
            scale: canvasState.scale,
            offset: canvasState.position,
          ),
          child: Container(),
        );
      },
    );
  }
}
