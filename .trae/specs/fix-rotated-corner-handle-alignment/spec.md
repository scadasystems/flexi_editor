# 회전 시 코너 오버레이 포인트 정렬 Spec

## Why
회전한 상태에서 도형 모서리의 오버레이 포인트(코너 리사이즈 핸들)가 모서리에서 살짝 벗어나 보입니다. 0도에서는 문제가 없거나 거의 느껴지지 않습니다.

## What Changes
- 코너 리사이즈 핸들 위치를 “도형 rect” 기준이 아니라, 하이라이트 테두리가 실제로 그려지는 외곽(rect + strokeWidth/2 확장) 기준으로 맞춘다
- 회전(Transform.rotate) 및 리사이즈 알고리즘(코너 추종)은 유지하고, **시각적 핸들 배치만** 보정한다

## Impact
- Affected specs: 선택 오버레이 렌더링 정합성
- Affected code:
  - `example/lib/editor/example_policy_set.dart` (`buildComponentOverWidget`, `_ResizeHandle`)

## ADDED Requirements
### Requirement: 회전 시 코너 정렬
시스템 SHALL 도형이 회전된 상태에서도 코너 오버레이 포인트가 하이라이트 테두리의 실제 모서리와 일치하도록 배치해야 한다.

#### Scenario: 0도와 비-0도 일관성
- **GIVEN** 단일 도형이 선택되어 있고 `rotationRadians`가 0 또는 임의의 값이다
- **WHEN** 선택 오버레이가 렌더링된다
- **THEN** 코너 포인트는 모든 회전각에서 테두리 모서리와 겹치며 벗어나지 않는다

## MODIFIED Requirements
해당 없음

## REMOVED Requirements
해당 없음

