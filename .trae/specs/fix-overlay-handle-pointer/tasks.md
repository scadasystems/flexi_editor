# Tasks
- [x] Task 1: 오버레이 핸들 히트테스트 영역 수정
  - [x] 핸들들이 도형 바운딩 박스 밖에서도 입력을 받도록 오버레이 레이아웃을 조정한다(예: 전체 캔버스 레이어에 절대좌표로 배치하거나, 부모 히트 영역을 핸들 여유분까지 확장).
  - [x] 핸들 이외 영역은 포인터를 흡수하지 않도록 유지한다.

- [x] Task 2: FlexiPointer 적용
  - [x] `package:flexi_editor/src/widget/flexi_pointer.dart`의 `FlexiPointer`로 리사이즈/회전 핸들 위젯을 감싼다.
  - [x] defer-pointer 구조(`DeferredPointerHandler`) 내에서 핸들 입력이 안정적으로 동작하는지 확인한다.

- [x] Task 3: 검증 및 문서 업데이트
  - [x] `flutter analyze`, `flutter test`, `flutter build web`를 통과한다.
  - [ ] 수동 검증: 도형 선택 후 코너/회전 핸들이 도형 밖에서도 드래그 가능한지 확인한다.
  - [x] 필요 시 example README에 “핸들 드래그”가 도형 밖에서도 동작함을 명시한다.

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 1, Task 2
