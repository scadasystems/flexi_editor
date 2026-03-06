# 회전 시 선택 오버레이 동기화 Spec

## Why
현재 도형을 회전하면 도형 본체만 회전하고, 선택 영역(하이라이트)과 오버레이 핸들(리사이즈/회전)은 회전하지 않아 UI가 어긋나고 조작이 어렵습니다.

## What Changes
- 선택 하이라이트(사각 테두리)와 오버레이 핸들을 도형의 `rotationRadians`에 맞춰 함께 회전시킨다
- 회전된 상태에서도 핸들 드래그(리사이즈/회전)가 동작하도록 입력 좌표계를 정리한다
- 기존 포인터 처리(FlexiPointer 기반) 및 “핸들 외 영역 비간섭” 동작은 유지한다

## Impact
- Affected specs: 선택 오버레이 렌더링, 회전/리사이즈 UX 일관성
- Affected code:
  - `example/lib/editor/example_policy_set.dart` (오버레이 렌더링/입력 변환)
  - `example/lib/editor/editor_models.dart` (이미 존재하는 rotationRadians 사용)

## ADDED Requirements
### Requirement: 회전된 선택 오버레이
시스템 SHALL 선택된 도형의 회전 각도(`rotationRadians`)에 따라 선택 하이라이트 및 오버레이 핸들을 동일한 기준(도형 중심)으로 회전시켜 표시해야 한다.

#### Scenario: 시각적 동기화
- **GIVEN** 단일 도형이 선택되어 있고 `rotationRadians != 0` 이다
- **WHEN** 도형이 렌더링된다
- **THEN** 선택 테두리와 핸들이 도형과 동일한 각도로 회전되어 표시된다

### Requirement: 회전 상태에서의 핸들 조작
시스템 SHALL 도형이 회전된 상태에서도 리사이즈/회전 핸들 조작이 가능해야 한다.

#### Scenario: 회전된 상태에서 리사이즈
- **GIVEN** 단일 도형이 회전되어 있고 선택 오버레이가 함께 회전되어 있다
- **WHEN** 사용자가 코너 리사이즈 핸들을 드래그한다
- **THEN** 도형의 크기/위치가 기대대로 변경된다(최소 크기 클램프 포함)

#### Scenario: 회전된 상태에서 추가 회전
- **GIVEN** 단일 도형이 회전되어 있고 선택 오버레이가 함께 회전되어 있다
- **WHEN** 사용자가 회전 핸들을 드래그한다
- **THEN** `rotationRadians`가 업데이트되어 도형/오버레이가 즉시 반영된다

## MODIFIED Requirements
### Requirement: 이벤트 비간섭 유지
시스템 SHALL 오버레이 핸들 자체 영역 이외의 영역에서는 기존 캔버스/도형 상호작용(선택 드래그, 이동 등)을 방해하지 않아야 한다.

## REMOVED Requirements
해당 없음

