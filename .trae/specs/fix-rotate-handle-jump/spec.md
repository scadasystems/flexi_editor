# 회전 핸들 드래그 점프 방지 Spec

## Why
`_RotateHandle`에서 마우스를 조금만 드래그해도 회전 각도가 갑자기 튀는 현상이 있어, 미세 조정이 어렵습니다.

## What Changes
- 회전 핸들 드래그를 “절대 각도”가 아닌 “드래그 시작 기준 상대 각도(delta)”로 계산해 첫 움직임에서도 회전이 튀지 않게 한다
- Shift 회전 스냅(45도 단위)은 상대 각도 계산 결과에 적용한다

## Impact
- Affected specs: 회전 UX, Shift 스냅 UX
- Affected code:
  - `example/lib/editor/example_policy_set.dart` (`_RotateHandle`)

## ADDED Requirements
### Requirement: 회전 점프 방지
시스템 SHALL 회전 핸들 드래그 시작 직후의 작은 드래그에서도 회전 각도가 갑자기 변하지 않도록, 드래그 시작 시점의 각도와 현재 각도의 차이로 회전을 계산해야 한다.

#### Scenario: 미세 드래그
- **GIVEN** 단일 도형이 선택되어 있고 현재 `rotationRadians`가 임의의 값이다
- **WHEN** 사용자가 회전 핸들을 아주 조금 드래그한다
- **THEN** 회전은 기존 각도에서 연속적으로 변화하며 첫 프레임에서 튀지 않는다

### Requirement: Shift 스냅 유지
시스템 SHALL Shift 키를 누른 상태에서 회전 핸들을 드래그하면 회전 각도를 45도 단위로 스냅해야 하며, 점프 방지 계산과 함께 동작해야 한다.

#### Scenario: 점프 없는 스냅
- **GIVEN** 단일 도형이 선택되어 있고 사용자가 Shift 키를 누르고 있다
- **WHEN** 사용자가 회전 핸들을 드래그한다
- **THEN** 회전은 45도 단위로 스냅되며, 드래그 시작 순간 각도가 튀지 않는다

## MODIFIED Requirements
해당 없음

## REMOVED Requirements
해당 없음

