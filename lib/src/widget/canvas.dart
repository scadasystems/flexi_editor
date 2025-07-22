// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:defer_pointer/defer_pointer.dart';
import 'package:flexi_editor/flexi_editor.dart';
import 'package:flexi_editor/src/canvas_context/canvas_event.dart';
import 'package:flexi_editor/src/canvas_context/canvas_model.dart';
import 'package:flexi_editor/src/utils/painter/selection_box_painter.dart';
import 'package:flexi_editor/src/widget/component.dart';
import 'package:flexi_editor/src/widget/link.dart';
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
  List<ComponentData> _cachedZOrderedComponents = [];
  List<Widget> _cachedComponentWidgets = [];
  List<Widget> _cachedLinkWidgets = [];

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

    // 컴포넌트가 변경되었는지 확인
    if (_cachedZOrderedComponents.length != currentComponents.length ||
        !_areComponentListsEqual(
            _cachedZOrderedComponents, currentComponents)) {
      _cachedZOrderedComponents = currentComponents;
      _cachedComponentWidgets = currentComponents
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

    return _cachedComponentWidgets;
  }

  bool _areComponentListsEqual(
      List<ComponentData> list1, List<ComponentData> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  List<Widget> showLinks(CanvasModel canvasModel) {
    final currentLinks = canvasModel.links.values.toList();

    // 링크 길이를 먼저 비교하여 변경 여부를 간단히 확인
    if (_cachedLinkWidgets.length != currentLinks.length) {
      _cachedLinkWidgets = currentLinks.map((LinkData linkData) {
        return ChangeNotifierProvider.value(
          value: linkData,
          child: Link(policy: widget.policy),
        );
      }).toList();
    }

    return _cachedLinkWidgets;
  }

  List<Widget> showOtherWithComponentDataUnder(CanvasModel canvasModel) {
    return canvasModel.components.values.map((ComponentData componentData) {
      return ChangeNotifierProvider.value(
        value: componentData,
        builder: (context, child) {
          return Consumer<ComponentData>(
            builder: (context, value, child) {
              return widget.policy.showCustomWidgetWithComponentDataUnder(
                  context, componentData);
            },
          );
        },
      );
    }).toList();
  }

  List<Widget> buildComponentOverWidget(CanvasModel canvasModel) {
    return canvasModel.components.values.map((ComponentData componentData) {
      return ChangeNotifierProvider.value(
        value: componentData,
        builder: (context, child) {
          return Consumer<ComponentData>(
            builder: (context, value, child) {
              return widget.policy.buildComponentOverWidget(context, value);
            },
          );
        },
      );
    }).toList();
  }

  List<Widget> showForegroundWidgets() {
    return widget.policy.showCustomWidgetsOnCanvasForeground(context);
  }

  List<Widget> buildLinkOverWidget(CanvasModel canvasModel) {
    return canvasModel.components.values.map((ComponentData componentData) {
      return ChangeNotifierProvider.value(
        value: componentData,
        builder: (context, child) {
          return Consumer<ComponentData>(
            builder: (context, data, child) {
              return widget.policy.buildLinkOverWidget(context, data);
            },
          );
        },
      );
    }).toList();
  }

  Widget canvasStack() {
    return Consumer3<CanvasState, CanvasEvent, CanvasModel>(
      builder: (context, state, event, model, child) {
        return DeferredPointerHandler(
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.expand,
            children: [
              GestureDetector(
                  onTap: () {
                    if (event.isTapComponent) return;
                    widget.policy.onCanvasTap();
                  },
                  onTapDown: (details) {
                    if (event.isTapComponent) return;
                    widget.policy.onCanvasTapDown(details);
                  },
                  onTapUp: (details) {
                    if (event.isTapComponent) return;
                    widget.policy.onCanvasTapUp(details);
                  },
                  onTapCancel: () {
                    if (event.isTapComponent) return;
                    widget.policy.onCanvasTapCancel();
                  },
                  child: Container(color: Colors.transparent)),
              ...showComponents(model),
              ...buildComponentOverWidget(model),
              ...showLinks(model),
              ...showForegroundWidgets(),
              ...buildLinkOverWidget(model),
            ],
          ),
        );
      },
    );
  }

  Widget canvasAnimated() {
    final animationController =
        (withControlPolicy as CanvasControlPolicy).getAnimationController();
    if (animationController == null) return canvasStack();

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
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
      child: canvasStack(),
    );
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

  /// 선택 드래그 영역
  Widget _buildSelectionBox(BuildContext context) {
    final canvasState = context.read<CanvasState>();

    return Consumer2<CanvasEvent, CanvasModel>(
      builder: (context, canvasEvent, canvasModel, child) {
        if (canvasEvent.startDragPosition != null &&
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
                widget.policy.onCanvasScaleStart(ScaleStartDetails(
                  focalPoint: details.localPosition,
                  pointerCount: 1,
                ));
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
              debugPrint(
                  '👇 포인터 다운 - ID: ${event.pointer}, 총 개수: $_activePointers, 위치: ${event.localPosition}');
              // 두 개의 포인터가 감지되면 pinch 시작으로 간주
              if (_activePointers == 2) {
                _isPinchActive = true;
                debugPrint('🤏 Pinch 시작 - 두 손가락 감지됨');
              }
            },
            onPointerUp: (event) {
              _activePointers--;
              debugPrint(
                  '👆 포인터 업 - ID: ${event.pointer}, 총 개수: $_activePointers, 위치: ${event.localPosition}');
              // 포인터가 2개 미만이 되면 pinch 종료
              if (_activePointers < 2 && _isPinchActive) {
                _isPinchActive = false;
                debugPrint('🤏 Pinch 종료 - 손가락 개수: $_activePointers');
              }
            },
            onPointerMove: (event) {
              // Pinch 상태에서만 move 이벤트 로그 출력 (스팸 방지를 위해 큰 움직임만)
              if (_isPinchActive && event.delta.distance > 2) {
                debugPrint(
                    '🤏 Pinch Move - 포인터 ID: ${event.pointer}, 위치: ${event.localPosition}, 델타: ${event.delta}');
              }
            },
            onPointerPanZoomStart: (event) {
              _isPinchActive = true;
              debugPrint('🤏 트랙패드 Pan-Zoom 시작 - 위치: ${event.localPosition}');
            },
            onPointerPanZoomUpdate: (event) {
              if (_isPinchActive) {
                debugPrint(
                    '🤏 트랙패드 Pan-Zoom 업데이트 - 위치: ${event.localPosition}, 델타: ${event.localPanDelta}, 스케일: ${event.scale.toStringAsFixed(3)}');
              }
            },
            onPointerPanZoomEnd: (event) {
              if (_isPinchActive) {
                _isPinchActive = false;
                debugPrint('🤏 트랙패드 Pan-Zoom 종료');
              }
            },
            onPointerSignal: (event) {
              // 트랙패드 두 손가락 스크롤(드래그) 감지
              if (event is PointerScrollEvent) {
                if (!_isPinchActive) {
                  _isPinchActive = true;
                  debugPrint('🤏 트랙패드 두 손가락 드래그 시작');
                }

                final scrollMagnitude = event.scrollDelta.distance;
                final scrollDirection =
                    event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
                        ? '수평'
                        : '수직';
                debugPrint(
                    '🤏 트랙패드 두 손가락 드래그 - 위치: ${event.localPosition}, 스크롤 델타: ${event.scrollDelta}, 방향: $scrollDirection, 세기: ${scrollMagnitude.toStringAsFixed(1)}');
                
                // 트랙패드 드래그는 onCanvasPointerSignal 호출하지 않음
                return;
              }
              // Scale 이벤트는 pinch/zoom 으로 처리
              else if (event.runtimeType.toString().contains('Scale')) {
                // 트랙패드 pinch 시작 시 상태 활성화
                if (!_isPinchActive) {
                  _isPinchActive = true;
                  debugPrint('🤏 트랙패드 Pinch 시작');
                }

                // 이벤트에서 스케일 정보를 추출 시도
                try {
                  // 속성 접근을 위해 dynamic으로 캐스팅
                  final dynamic scaleEvent = event;

                  // 스케일 이벤트의 일반적인 속성명들을 시도
                  dynamic scaleValue;
                  dynamic deltaValue;
                  dynamic focusPoint;

                  try {
                    scaleValue = scaleEvent.scale;
                  } catch (_) {}
                  try {
                    deltaValue = scaleEvent.scaleDelta;
                  } catch (_) {}
                  try {
                    deltaValue ??= scaleEvent.delta;
                  } catch (_) {}
                  try {
                    focusPoint = scaleEvent.focalPoint;
                  } catch (_) {}
                  try {
                    focusPoint ??= scaleEvent.localPosition;
                  } catch (_) {}

                  if (scaleValue != null) {
                    final direction = scaleValue > 1.0
                        ? 'Zoom In'
                        : scaleValue < 1.0
                            ? 'Zoom Out'
                            : 'No Change';
                    debugPrint(
                        '🤏 Trackpad Pinch - Scale: ${scaleValue.toStringAsFixed(3)}, Direction: $direction');
                    if (focusPoint != null) {
                      debugPrint('🤏 Trackpad Pinch - Focus: $focusPoint');
                    }
                  } else if (deltaValue != null) {
                    debugPrint('🤏 Trackpad Pinch - Delta: $deltaValue');
                  } else {
                    // 대안: 전체 이벤트 정보만 표시
                    debugPrint('🤏 Trackpad Pinch - Event: $event');
                  }

                  // 트랙패드 Pinch도 onCanvasPointerSignal 호출하지 않음
                  return;
                } catch (e) {
                  debugPrint('🚫 Could not extract scale info: $e');
                  debugPrint('🤏 Raw Trackpad Event: $event');
                  // 에러 발생 시에도 onCanvasPointerSignal 호출하지 않음
                  return;
                }
              }

              // 다른 이벤트만 정책으로 전달
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
