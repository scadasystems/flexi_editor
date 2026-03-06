# ExamplePolicySet 분리 Spec

## Why
`example_policy_set.dart` 파일이 여러 역할(도형 렌더링, 선택 오버레이/핸들, 리사이즈/회전 제스처 로직)을 한 파일에 포함하고 있어 가독성이 떨어지고 유지보수가 어렵습니다.

## What Changes
- `ExamplePolicySet` 본체와 선택 오버레이(하이라이트/핸들) 구현을 파일 단위로 분리한다
- `_ResizeHandle`, `_RotateHandle` 및 관련 유틸 함수는 별도 파일로 이동한다
- 공개 API/동작은 변경하지 않는다 (**BREAKING 없음**)

## Impact
- Affected specs: 예제 코드 가독성/구조화
- Affected code:
  - `example/lib/editor/example_policy_set.dart`
  - 신규 파일들(예: `example/lib/editor/policy/*`)

## ADDED Requirements
### Requirement: 파일 분리
시스템 SHALL `ExamplePolicySet` 관련 구현을 역할 단위로 파일을 분리해, 각 파일이 단일 책임을 갖도록 구성해야 한다.

#### Scenario: 기능 동일성
- **GIVEN** 기존 예제 앱이 동작한다
- **WHEN** 파일을 분리한 뒤 빌드/실행한다
- **THEN** 렌더링/선택/리사이즈/회전 동작은 기존과 동일하게 동작한다

## MODIFIED Requirements
해당 없음

## REMOVED Requirements
해당 없음

