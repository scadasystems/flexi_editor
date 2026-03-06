# Shift 비율 고정 리사이즈 Spec

## Why
현재는 리사이즈 드래그 시 폭/높이를 자유롭게 변경할 수 있지만, Shift 키를 누른 상태에서는 도형의 **원래 비율(가로:세로)** 을 유지하며 크기를 조정하고 싶습니다.

## What Changes
- 코너 리사이즈 핸들 드래그 중 Shift 키가 눌려 있으면, 드래그 시작 시점의 도형 비율을 유지하도록 크기 계산을 보정한다
- 회전 상태에서도 동일하게 적용한다(로컬 축 기준 비율 유지)
- 최소 크기 클램프 및 기존 코너-고정(반대 코너 고정) 리사이즈 동작은 유지한다

## Impact
- Affected specs: 리사이즈 UX
- Affected code:
  - `example/lib/editor/policy/resize_handle.dart` (`_ResizeHandleState`)

## ADDED Requirements
### Requirement: Shift 비율 고정 리사이즈
시스템 SHALL 코너 리사이즈 드래그 중 Shift 키가 눌려 있으면, 드래그 시작 시점의 도형 비율을 유지하며 크기를 조정해야 한다.

#### Scenario: 기본 비율 유지
- **GIVEN** 단일 도형이 선택되어 있고 초기 크기가 `(w, h)` 이다
- **WHEN** 사용자가 Shift 키를 누른 상태에서 코너 핸들을 드래그한다
- **THEN** 리사이즈 결과는 `width / height == w / h` 를 유지한다(허용 오차 내)

#### Scenario: 회전 상태에서도 동일
- **GIVEN** 단일 도형이 회전되어 있고(`rotationRadians != 0`) 초기 크기가 `(w, h)` 이다
- **WHEN** 사용자가 Shift 키를 누른 상태에서 코너 핸들을 드래그한다
- **THEN** 도형은 회전과 무관하게 초기 비율을 유지한다

### Requirement: 드래그 중 Shift 토글 동작
시스템 SHALL 코너 드래그 도중 Shift 키가 눌리거나(OFF→ON) 해제되는(ON→OFF) 경우에도, 리사이즈 결과가 순간적으로 튀지 않고 연속적으로 동작해야 한다.

#### Scenario: 드래그 중 Shift를 누른 경우
- **GIVEN** 사용자가 코너 핸들을 드래그 중이며 Shift 키가 눌려 있지 않다
- **WHEN** 사용자가 드래그 도중 Shift 키를 누른다
- **THEN** 현재 프레임에서의 도형 크기를 기준 비율로 삼아(해당 시점의 `width/height`), 이후 드래그는 그 비율을 유지하며 연속적으로 동작한다

#### Scenario: 드래그 중 Shift를 뗀 경우
- **GIVEN** 사용자가 코너 핸들을 드래그 중이며 Shift 비율 고정이 활성화되어 있다
- **WHEN** 사용자가 드래그 도중 Shift 키를 뗀다
- **THEN** 도형은 현재 크기에서 연속적으로 이어서 자유 리사이즈로 전환된다(비율 고정 해제)

## MODIFIED Requirements
해당 없음

## REMOVED Requirements
해당 없음
