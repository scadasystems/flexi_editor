# 도형 크기 조절(Resize) + 회전(Rotation) 기능 추가 계획

## 목표
- example “Figma clone” 앱에서 선택된 도형(사각형/타원)의 크기를 마우스로 조절할 수 있게 한다.
- example “Figma clone” 앱에서 선택된 도형(사각형/타원)을 마우스로 회전할 수 있게 한다.
- Web(Chrome) 기준으로 자연스러운 마우스 커서/드래그 동작을 제공한다.

## 현재 동작 요약(확인된 상태)
- 도형 이동: `ExamplePolicySet.onComponentScaleUpdate`에서 `focalPointDelta` 기반 이동 처리.
- 도형 생성: 드래그 선택 영역 콜백(`onSelectionRectUpdate`)을 “Rectangle/Oval” 툴에서 활용해 임시 컴포넌트 생성/업데이트.
- 선택 표시: `ExamplePolicySet.buildComponentOverWidget`에서 하이라이트만 렌더링(현재는 포인터 무시).

## 구현 범위
- 선택된 도형(단일 선택)에 리사이즈 핸들(코너 4개)을 표시
- 핸들 드래그로 크기 변경(+ 필요한 경우 위치 변경)
- 최소 크기(예: 16x16) 이하로 줄어들지 않도록 클램프
- 링크가 연결된 도형의 경우, 크기 변경 후 링크 엔드포인트가 갱신되도록 처리
- 선택된 도형(단일 선택)에 회전 핸들(상단 중앙 1개)을 표시
- 회전 핸들 드래그로 각도 변경(도형의 “시각적 회전”)

## 비범위
- 다중 선택 동시 리사이즈/회전, 정밀 스냅/그리드 스냅, 비율 고정(Shift) 등 고급 기능

## 변경/추가 파일(예정)
- 수정
  - `example/lib/editor/example_policy_set.dart` (선택 오버레이에 리사이즈 핸들 추가)
  - `example/lib/editor/editor_models.dart` (도형 데이터에 rotation 값 추가)
  - `example/lib/pages/editor_page.dart` (필요 시: 선택/드래그 충돌 최소화, 단축키/툴 상태와의 상호작용 정리)
  - `example/README.md` (사용 방법에 “리사이즈” 항목 추가)
- 추가(필요 시)
  - `example/lib/editor/resize_handles.dart` (핸들 위젯/로직 분리)

## 설계(핵심 아이디어)
- 리사이즈는 “선택 오버레이”에서만 처리한다.
  - 즉, 도형 본체의 `onScaleUpdate`는 계속 “이동”에만 사용하고,
  - 리사이즈는 오버레이 핸들의 `GestureDetector`로 별도 처리한다.
- 회전도 “선택 오버레이”에서만 처리한다.
  - 회전 값은 도형의 `data`(예: `EditorShapeData`)에 저장하고,
  - `showComponentBody`에서 `Transform.rotate`로 “시각적 회전”을 적용한다.
  - 1차 구현은 “축 정렬된 바운딩 박스”는 유지한다(즉, 선택/리사이즈/히트테스트는 회전을 고려하지 않음).
- 오버레이는 캔버스 스케일/포지션을 반영해 **스크린 좌표**로 배치한다.
  - 현재 하이라이트가 계산하는 `left/top/width/height` 공식을 그대로 재사용한다.
- 드래그 델타는 `canvasState.scale`로 나눠 **캔버스 좌표 델타**로 변환한다.

## 리사이즈 규칙(코너 4개)
- 기준: 캔버스 좌표계에서 `Rect(pos, size)`를 업데이트
- TopLeft
  - `position += delta`
  - `size -= delta`
- TopRight
  - `position += Offset(0, delta.dy)`
  - `size += Offset(delta.dx, -delta.dy)`
- BottomLeft
  - `position += Offset(delta.dx, 0)`
  - `size += Offset(-delta.dx, delta.dy)`
- BottomRight
  - `size += delta`
- 공통 클램프
  - `minWidth/minHeight` 이하로 줄어드는 경우, 해당 축 변화량을 제한하고(클램프) 위치 보정이 필요한 핸들은 함께 보정한다.

## 캔버스/모델 업데이트 방식
- 크기: `canvasWriter.model.setComponentSize(componentId, newSize)`
- 위치: `canvasWriter.model.setComponentPosition(componentId, newPosition)`
- 링크 갱신: 크기 변경 후 `canvasWriter.model.updateComponentLinks(componentId)` 호출(엔드포인트/정렬 재계산)

## UX 디테일
- 핸들 크기: 스크린 기준 8~10px 정사각형(흰 배경 + 파란 테두리)
- 마우스 커서
  - TL/BR: `resizeUpLeftDownRight`
  - TR/BL: `resizeUpRightDownLeft`
- 회전 핸들
  - 위치: 도형 상단 중앙에서 일정 거리(예: 18px) 위
  - 모양: 작은 원(흰 배경 + 파란 테두리)
  - 드래그 시 도형 중심을 기준으로 각도를 계산해 업데이트
- 단일 선택일 때만 핸들 표시(다중 선택에서는 하이라이트만 유지)

## 구현 단계(실행 시 그대로 수행)
1. 오버레이 핸들 UI 추가
   - `buildComponentOverWidget`가 하이라이트 + 리사이즈 핸들 + 회전 핸들(포인터 처리 포함)을 렌더링하도록 변경
2. 핸들 드래그 로직 구현
   - 드래그 시작 시 원본 `position/size` 스냅샷 저장
   - 드래그 업데이트마다 새 `position/size` 계산 → 클램프 → writer로 반영 → 링크 업데이트
3. 회전 로직 구현
   - `EditorShapeData`에 `rotationRadians`(double) 추가(기본 0)
   - 회전 핸들 드래그 시 포인터의 “캔버스 좌표”를 얻어 도형 중심과의 각도를 계산
     - 전역 포인터 좌표를 `canvasState.canvasGlobalKey`의 RenderBox로 `globalToLocal` 변환
     - `canvasPoint = (localPoint - canvasState.position) / canvasState.scale`
     - `angle = atan2(canvasPoint.dy - center.dy, canvasPoint.dx - center.dx)`
   - `showComponentBody`에서 `Transform.rotate(angle: rotationRadians, alignment: Alignment.center, child: ...)` 적용
3. 이벤트 충돌 점검
   - 핸들 조작 중에는 캔버스 선택 드래그가 개입하지 않도록(오버레이가 포인터를 먹도록) 위젯 트리 구성 확인
4. 문서 보강
   - `example/README.md`에 리사이즈/회전 사용 방법 추가
5. 검증
   - `flutter analyze` 통과
   - `flutter test` 통과
   - 수동 시나리오(웹)
     - 사각형 생성 → 선택 → 코너 드래그 리사이즈
     - 타원도 동일하게 리사이즈
     - 링크 연결 후 도형 리사이즈 시 링크 엔드포인트가 따라오는지 확인
     - 선택된 도형 회전 핸들 드래그 시 시각적으로 회전하는지 확인

## 성공 기준
- 선택된 도형에 4개 코너 핸들이 표시된다.
- 코너 핸들을 드래그하면 도형 크기가 기대대로 변경된다(최소 크기 보장).
- 링크가 연결된 도형을 리사이즈해도 링크가 즉시 갱신된다.
- 선택된 도형에 회전 핸들이 표시된다.
- 회전 핸들을 드래그하면 도형이 시각적으로 회전한다.
- Web 빌드/테스트/분석이 모두 통과한다.
