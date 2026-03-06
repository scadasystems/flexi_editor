# 회전 상태 리사이즈 입력 보정 Spec

## Why
도형이 회전된 상태에서 리사이즈 핸들을 드래그하면, 동일한 마우스 이동량 대비 크기 변경이 회전각에 따라 달라져 “회전율과 비례하지 않는 느낌”이 듭니다.

## What Changes
- 리사이즈 드래그 입력(`details.delta`)을 도형의 로컬 축으로 변환한 뒤(회전각의 역회전), 기존 리사이즈 알고리즘에 적용한다
- 최소 크기 클램프 및 링크 업데이트 등 기존 동작은 유지한다

## Impact
- Affected specs: 회전/리사이즈 UX 일관성
- Affected code:
  - `example/lib/editor/example_policy_set.dart` (`_ResizeHandle`)

## ADDED Requirements
### Requirement: 회전 상태 리사이즈 일관성
시스템 SHALL 도형이 회전된 상태에서도 리사이즈 핸들 드래그가 도형 로컬 축 기준으로 동작해, 회전각에 따라 리사이즈 감도가 달라지지 않게 해야 한다.

#### Scenario: 다양한 회전각에서 동일 감도
- **GIVEN** 단일 도형이 선택되어 있고 `rotationRadians`가 0/30/45/90 중 하나이다
- **WHEN** 사용자가 코너 리사이즈 핸들을 동일한 화면 이동량으로 드래그한다
- **THEN** 도형의 폭/높이 변화량은 회전각에 따라 부자연스럽게 달라지지 않는다(로컬 축 기준으로 일관)

## MODIFIED Requirements
해당 없음

## REMOVED Requirements
해당 없음

