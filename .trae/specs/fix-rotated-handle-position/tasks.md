# Tasks
- [x] Task 1: 오버레이 좌표계/회전 기준점 재구성
  - [x] 선택 오버레이를 “컴포넌트 화면 rect + 충분한 패딩”을 갖는 로컬 컨테이너로 만든다.
  - [x] 로컬 컨테이너 내부에서 하이라이트/핸들을 로컬 좌표로 배치하고, 도형 중심을 기준으로 전체를 회전시킨다.

- [x] Task 2: 핸들 배치 정밀화
  - [x] 코너 리사이즈 핸들이 회전된 선택 박스 코너에 맞도록 상대 위치를 정리한다.
  - [x] 회전 핸들이 “상단 중앙 + 고정 오프셋” 위치를 유지하도록 한다.

- [x] Task 3: Shift 회전 스냅 추가
  - [x] Shift 키가 눌린 상태를 감지한다(예: `HardwareKeyboard.instance.isShiftPressed`).
  - [x] Shift 상태에서 회전 각도를 45도 단위로 스냅한다(가장 가까운 `n * (π/4)`).

- [x] Task 4: 동작/회귀 검증
  - [x] 수동 검증(웹): 회전 각도 0/30/45/90에서 핸들 위치가 일관되고 정확한지 확인한다.
  - [x] 수동 검증(웹): Shift를 누른 채 회전 시 0/45/90/…로 스냅되는지 확인한다.
  - [x] 수동 검증(웹): 핸들 드래그(리사이즈/회전) 및 핸들 외 영역 비간섭이 유지되는지 확인한다.
  - [x] `flutter analyze`, `flutter build web`를 통과한다.

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 1, Task 2
- Task 4 depends on Task 1, Task 2, Task 3
