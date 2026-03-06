# 오버레이 핸들 포인터 처리 Spec

## Why
현재 도형 선택 오버레이의 리사이즈/회전 핸들이 도형 바운딩 박스 밖에 위치할 때 클릭/드래그가 되지 않아 편집 기능이 막힙니다.

## What Changes
- 선택 오버레이 핸들이 도형 영역 밖에 있어도 포인터 이벤트를 정상 수신하도록 히트 테스트 영역을 수정
- `flexi_pointer.dart`의 `FlexiPointer`(DeferPointer 래퍼)를 사용해 오버레이 핸들이 캔버스의 defer-pointer 구조 안에서 안정적으로 동작하도록 적용
- 핸들 외 영역은 포인터를 가로채지 않도록 유지(기존 선택/이동/캔버스 조작에 영향 최소화)

## Impact
- Affected specs: 선택 오버레이(하이라이트/핸들) 상호작용, 드래그 리사이즈/회전 UX
- Affected code:
  - `example/lib/editor/example_policy_set.dart` (오버레이 레이아웃/포인터 처리 변경)
  - `lib/src/widget/flexi_pointer.dart` (사용만; 기능 변경은 없음)

## ADDED Requirements
### Requirement: 오버레이 핸들 포인터 수신
시스템 SHALL 도형 선택 오버레이의 리사이즈/회전 핸들이 도형 바운딩 박스 밖에 위치하더라도 클릭/드래그 입력을 수신할 수 있어야 한다.

#### Scenario: 리사이즈 핸들 드래그 성공
- **GIVEN** 단일 도형이 선택되어 있고, 코너 리사이즈 핸들이 표시되어 있다
- **WHEN** 사용자가 핸들을 드래그한다(도형 바운딩 박스 밖에서 시작해도 포함)
- **THEN** 도형의 크기/위치가 기대대로 변경된다

#### Scenario: 회전 핸들 드래그 성공
- **GIVEN** 단일 도형이 선택되어 있고, 상단 회전 핸들이 표시되어 있다
- **WHEN** 사용자가 회전 핸들을 드래그한다(도형 바운딩 박스 밖에서 시작)
- **THEN** 도형이 시각적으로 회전한다

## MODIFIED Requirements
### Requirement: 선택 오버레이의 이벤트 비간섭
시스템 SHALL 오버레이 핸들 자체 영역 이외의 영역에서는 기존 캔버스/도형 상호작용(선택 드래그, 이동 등)을 방해하지 않아야 한다.

## REMOVED Requirements
해당 없음

