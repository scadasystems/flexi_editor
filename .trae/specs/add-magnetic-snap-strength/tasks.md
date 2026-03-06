# Tasks
- [x] Task 1: 스냅 강도(임계값) 설정을 라이브러리 설정에 추가
  - [x] `CanvasDottedBackgroundConfig`에 스냅 임계값 필드를 추가한다.
  - [x] `CanvasStateWriter`를 통해 설정을 변경할 수 있게 한다(기존 패턴 유지).

- [x] Task 2: 예제 스냅 로직에서 설정값을 사용
  - [x] 하드코딩된 스냅 임계값을 제거하고 설정값을 사용한다.

- [x] Task 3: 검증
  - [x] `flutter analyze`, `flutter build web`를 통과한다.

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 2
