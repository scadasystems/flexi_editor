# 회전 핸들 오버레이 동기 회전 Spec

## Why
현재 구현은 회전 핸들이 오버레이와 함께 회전하지 않아, 리사이즈 핸들/하이라이트와 달리 회전 핸들이 따로 노는 것처럼 보입니다.

## What Changes
- 회전 핸들을 선택 오버레이(하이라이트/리사이즈 핸들)와 동일하게 도형 회전에 맞춰 함께 회전하도록 변경한다
- 회전 핸들의 기준 위치는 “도형 로컬 상단 중앙 + 고정 오프셋”으로 유지한다
- 기존 Shift 스냅(45도 단위) 및 회전 점프 방지(상대 각도 delta)는 유지한다

## Impact
- Affected specs: 선택 오버레이 렌더링, 회전 UX
- Affected code:
  - `example/lib/editor/example_policy_set.dart` (`buildComponentOverWidget`, `_RotateHandle`)

## ADDED Requirements
### Requirement: 회전 핸들 동기 회전
시스템 SHALL 도형이 회전될 때 회전 핸들이 선택 오버레이와 동일한 기준으로 함께 회전되어 표시되어야 한다.

#### Scenario: 오버레이와 동일 회전
- **GIVEN** 단일 도형이 선택되어 있고 `rotationRadians != 0` 이다
- **WHEN** 선택 오버레이가 렌더링된다
- **THEN** 회전 핸들은 리사이즈 핸들/하이라이트와 함께 동일한 각도로 회전되어 표시된다

### Requirement: 회전 UX 유지
시스템 SHALL 회전 핸들 드래그의 점프 방지(드래그 시작 기준 상대 각도 delta)와 Shift 스냅(45도 단위)을 유지해야 한다.

#### Scenario: 점프 없는 스냅
- **GIVEN** 단일 도형이 선택되어 있고 사용자가 Shift 키를 누르고 있다
- **WHEN** 사용자가 회전 핸들을 드래그한다
- **THEN** 회전은 점프 없이 연속적으로 변하며 45도 단위로 스냅된다

## MODIFIED Requirements
해당 없음

## REMOVED Requirements
해당 없음

