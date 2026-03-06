# 회전 시 오버레이 핸들 위치 고정 Spec

## Why
회전값(`rotationRadians`)이 변경되면 오버레이 핸들(특히 회전 핸들)의 위치가 함께 회전하면서, 도형이 시각적으로 동일해 보이는 경우(예: 정사각형 90도 회전)에도 핸들이 다른 위치로 이동해 어색합니다.

## What Changes
- 회전 핸들을 “도형 로컬 상단”이 아니라 “화면 기준 상단(최상단 y)”에 고정되도록 배치한다
  - 회전된 선택 박스(OBB)의 4개 코너를 화면 기준으로 회전시켜 최상단 y를 구하고, 그 위로 오프셋만큼 회전 핸들을 배치한다
  - 회전 핸들은 오버레이 그룹 회전의 영향을 받지 않는다
- 리사이즈 핸들 및 선택 하이라이트는 기존대로 도형 회전에 맞춰 함께 회전한다
- Shift 스냅(45도 단위)은 유지한다

## Impact
- Affected specs: 선택 오버레이 렌더링, 회전 UX 정합성
- Affected code:
  - `example/lib/editor/example_policy_set.dart` (`buildComponentOverWidget`, `_RotateHandle`)

## ADDED Requirements
### Requirement: 화면 기준 회전 핸들 위치
시스템 SHALL 도형이 회전된 상태에서도 회전 핸들이 화면 기준으로 도형의 최상단 외곽 위에 일정 오프셋으로 표시되도록 해야 한다.

#### Scenario: 정사각형 90도 회전
- **GIVEN** 정사각형 도형이 선택되어 있고 `rotationRadians`가 0 또는 `π/2` 이다
- **WHEN** 선택 오버레이가 렌더링된다
- **THEN** 회전 핸들은 두 경우 모두 화면 기준 “상단 중앙” 부근에 동일하게 표시된다

#### Scenario: 임의 각도 회전
- **GIVEN** 도형이 선택되어 있고 `rotationRadians != 0` 이다
- **WHEN** 선택 오버레이가 렌더링된다
- **THEN** 회전 핸들은 회전된 도형의 최상단 외곽 위로 일정 거리만큼 떨어져 표시된다

## MODIFIED Requirements
해당 없음

## REMOVED Requirements
해당 없음

