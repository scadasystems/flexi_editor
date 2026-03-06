# 마그네틱 스냅 강도 설정 Spec

## Why
도형 이동 시 그리드 마그네틱 스냅이 너무 강하게 느껴져, 프로젝트/상황에 따라 스냅 강도를 조절할 필요가 있습니다.

## What Changes
- 마그네틱 스냅의 “강도”를 **스냅 임계값(근접 거리)** 으로 정의하고 설정으로 노출한다
- 라이브러리 설정(`CanvasDottedBackgroundConfig`)에 스냅 임계값 필드를 추가한다
- 예제 이동 스냅 로직이 하드코딩된 임계값 대신 설정값을 사용한다
- 기본 동작은 기존과 동일하게 유지한다(기본값으로 현재 체감과 동일한 수준)

## Impact
- Affected specs: 이동 UX, 그리드 스냅 체감
- Affected code:
  - `lib/src/canvas_context/canvas_dotted_background_config.dart`
  - `example/lib/editor/example_policy_set.dart` (또는 이동 정책 코드)

## ADDED Requirements
### Requirement: 스냅 강도 설정
시스템 SHALL 마그네틱 스냅 임계값을 설정할 수 있어야 하며, 이 값으로 스냅 체감을 조절할 수 있어야 한다.

#### Scenario: 임계값이 작을수록 약한 스냅
- **GIVEN** 마그네틱 스냅 임계값이 작은 값으로 설정되어 있다
- **WHEN** 사용자가 도형을 드래그해 그리드 교차점 근처로 이동한다
- **THEN** 더 가까운 경우에만 스냅이 발생해 스냅 체감이 약해진다

#### Scenario: 임계값이 클수록 강한 스냅
- **GIVEN** 마그네틱 스냅 임계값이 큰 값으로 설정되어 있다
- **WHEN** 사용자가 도형을 드래그해 그리드 교차점 근처로 이동한다
- **THEN** 더 먼 거리에서도 스냅이 발생해 스냅 체감이 강해진다

## MODIFIED Requirements
해당 없음

## REMOVED Requirements
해당 없음

