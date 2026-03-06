# 캔버스 점선(도트) 패턴 + 마그네틱 스냅 구현 계획

## 목표

* 캔버스 “바탕”에 점선(도트) 패턴을 표시한다. (라이브러리 기능으로 제공)

* 도트(그리드) 기준으로 컴포넌트 이동 시 위치가 “마그네틱(near snap)”하게 붙도록 한다.

* 도트 배경은 기본 OFF이며, **enable 설정**으로 켜고 끌 수 있어야 한다.

## 전제/해석(본 계획에서 채택)

* “점선 패턴”은 **도트 그리드(점들이 일정 간격으로 반복되는 패턴)** 로 구현한다.

* “마그네틱”은 **그리드 교차점 근처(임계값 이내)에서만 스냅**되고, 멀면 자유 이동한다.

* 스냅 기준점은 **컴포넌트의 position(좌상단)** 으로 한다(현재 모델 좌표 체계 유지).

## 변경 지점 조사 결과(핵심)

* 캔버스 배경은 현재 단색 `Container(color: canvasState.color)`만 존재한다: `lib/src/widget/canvas.dart`

* 정책에서 캔버스에 커스텀 위젯을 꽂는 훅이 있다: `CanvasWidgetsPolicy.showCustomWidgetsOnCanvasBackground/Foreground`

  * 단, 현재 “background” 훅은 컴포넌트 아래가 아니라 **컴포넌트 위 레이어**에 들어간다(정확한 “바탕”을 원하면 레이어 순서 조정이 필요).

* 이동 입력은 컴포넌트 위젯의 제스처가 `policy.onComponentScaleUpdate`로 들어온다.

  * 예제는 `ExamplePolicySet.onComponentScaleUpdate`에서 이동을 처리한다.

## 구현 단계

### 1) 도트(점선) 배경을 “라이브러리 설정”으로 추가

1. 라이브러리 레벨 설정 모델을 추가한다.

   * 예: `CanvasDottedBackgroundConfig`

     * `enabled` (bool)

     * `gridSpacingCanvas` (double)

     * `dotRadiusCanvas` (double, “캔버스 좌표” 기준)

     * `color` (Color)
2. `CanvasWriter.state`(또는 `CanvasState`)에 enable/설정 변경 API를 추가한다.

   * 예: `setDottedBackground(CanvasDottedBackgroundConfig config)` 혹은

     * `setDottedBackgroundEnabled(bool enabled)`

     * `setDottedBackgroundStyle(...)`

   * 기본값은 `enabled=false`로 둔다(기존 동작 보존).
3. `CustomPainter`(예: `DottedGridPainter`)를 라이브러리에 추가한다.

   * 입력: `CanvasDottedBackgroundConfig` + `CanvasState`(position/scale)

   * 동작:

     * 도트를 **월드(캔버스) 좌표 기준**으로 반복 배치

     * 현재 뷰포트에 해당하는 점만 그려 성능을 유지

     * 줌(스케일)에 따라 화면에서 도트가 같이 확대/축소되는(월드 고정) 동작을 기본으로 한다
4. `lib/src/widget/canvas.dart`에서 “진짜 배경” 레이어에 조건부로 도트 painter를 삽입한다.

   * `enabled=true`일 때만 `Positioned.fill -> CustomPaint(painter: ...)`를 렌더링

   * 컴포넌트/링크보다 아래에 위치하도록 스택 순서를 조정한다(사용자가 요청한 “바탕” 충족).

### 2) 마그네틱(near snap) 스냅 로직(최소 침습)

1. 스냅 파라미터를 정의한다.

   * `gridSpacingCanvas` (예: 24.0)

   * `snapThresholdCanvas` (예: 6.0)
2. 이동 업데이트 시(드래그 중) 스냅을 적용한다.

   * 적용 위치: 예제 기준 `ExamplePolicySet.onComponentScaleUpdate`

   * 계산 방식:

     1. 월드 델타 `deltaCanvas = details.focalPointDelta / canvasState.scale`
     2. 후보 위치 `candidate = currentPos + deltaCanvas`
     3. 가장 가까운 그리드 점 `snapped = round(candidate / spacing) * spacing`
     4. `distance(candidate, snapped) <= threshold`이면 `target = snapped`, 아니면 `target = candidate`
     5. `moveComponentWithChildren`를 계속 사용하기 위해, 최종 월드 델타 `finalDeltaCanvas = target - currentPos`를 구한 뒤

        * `finalDeltaScreen = finalDeltaCanvas * canvasState.scale`로 환산해서 `moveComponentWithChildren(componentId, finalDeltaScreen)` 호출
3. 스냅 기준점은 우선 `position(좌상단)`으로 하되, 필요 시 “센터 스냅” 옵션을 쉽게 추가할 수 있게 계산을 함수로 분리한다(과도한 추상화는 하지 않음).

### 3) UX/일관성 체크(수동)

* 패닝/줌 시 도트 그리드가 “월드에 고정된 느낌”으로 유지되는지 확인한다.

* 도형을 그리드 점 근처로 이동하면 자연스럽게 붙고, 멀리서는 자유 이동되는지 확인한다.

* 스냅이 컴포넌트 1개뿐 아니라 `moveComponentWithChildren` 경로에서도 동일하게 적용되는지 확인한다.

### 4) 검증(자동)

* example 기준:

  * `flutter analyze`

  * `flutter build web`

## 산출물(파일/코드 변경 예상)

* 코어(플러그인):

  * `lib/src/widget/canvas.dart` (배경 레이어 추가/순서 조정)

  * (신규) 도트 배경 설정 모델 + painter 파일

    * 예: `lib/src/canvas_context/canvas_dotted_background_config.dart`

    * 예: `lib/src/utils/painter/dotted_grid_painter.dart`

  * (수정) `CanvasWriter.state`/`CanvasState`에 도트 배경 enable 설정 API 추가

* 예제:

  * `example/lib/editor/example_policy_set.dart` (이동 스냅 로직 적용)

  * 또는 예제 정책 관련 파일(분리된 policy 파일 포함)로 이동 적용

## 완료 조건

* 캔버스 배경에 도트 패턴이 보인다(컴포넌트 아래).

* 컴포넌트 이동 시 그리드 점 근처에서 마그네틱 스냅이 동작한다.

* example의 `flutter analyze`, `flutter build web`가 통과한다.

