# flexi_editor example + Figma Clone(Web) 생성 계획

## 목표
- 이 저장소(Flutter 플러그인/패키지) 내에 `example/` Flutter 앱을 추가한다.
- `flexi_editor`를 사용해 “Figma clone” 성격의 간단한 편집 앱을 구현한다.
- Web(Chrome)에서 실행/빌드 가능한 형태로 구성한다.

## 산출물(생성/수정될 주요 파일)
- `example/` Flutter 앱(웹 포함)
  - `example/pubspec.yaml`
  - `example/lib/main.dart` 및 앱 코드(페이지/위젯/상태)
  - `example/web/*` (Flutter 기본 웹 엔트리)
- (필요 시) 플러그인 API 사용을 위한 최소 보조 코드
  - 예: `example/lib/editor/policy_set.dart`(예제용 PolicySet 구성)

## 범위
- 캔버스 편집: 패닝/줌, 선택(드래그 선택 포함), 컴포넌트(사각형/타원) 생성, 이동, 삭제
- 링크(커넥터) 생성 및 조작(가능한 범위 내에서 기본 제공 정책 활용)
- 간단한 UI: 좌측 툴바(선택/사각형/타원/커넥터), 상단 바(Undo/Redo/Zoom 표시 정도), 우측 속성 패널(선택된 오브젝트 기본 속성 표시)
- Web 입력 경험: 마우스 휠 줌, 트랙패드 스크롤 패닝(패키지 내 기본 정책 활용 가능 여부 확인 후 적용)

## 비범위(이번 요청에서 제외)
- 실시간 협업, 멀티 페이지, 오토 레이아웃, 텍스트 편집기, 벡터 패스 편집
- 완전한 Figma UI/단축키/정밀 스냅(그리드/가이드) 전체 구현
- 퍼시스턴스(파일 저장/불러오기) 및 내보내기(SVG/PNG)

## 전제/가정
- `flexi_editor`는 플랫폼 채널을 사용하지 않는 순수 Flutter 위젯/로직 중심이라 Web에서 동작 가능하다.
- 예제 앱은 `flexi_editor`의 현재 공개 API(`FlexiEditor`, `FlexiEditorContext`, `PolicySet`, 모델/상태 writer/reader)를 직접 사용한다.
- 기존 코드 스타일을 따른다(특히 Dart 3, Flutter 최신 린트). 사용자 규칙: “항상 한국어”, “dot shorthands 사용”, “withOpacity 대신 withValues(alpha: …) 사용”.

## 구현 단계(실행 단계에서 그대로 수행)
1. 예제 앱 스캐폴딩 생성
   - `example/` 디렉터리 생성
   - Flutter 앱을 Web 포함으로 생성(기본 `web/` 엔트리 포함)
   - `example/pubspec.yaml`에 로컬 패키지 의존성 추가: `flexi_editor: { path: ../ }`

2. 예제용 PolicySet 구성
   - `PolicySet`를 확장/조합해 웹 입력(줌/패닝)과 링크 편집에 필요한 기본 정책을 믹스인으로 구성
     - 후보: `CanvasControlPolicy`, `LinkControlPolicy`, `LinkJointControlPolicy`, 링크 attachment 정책(oval/rect/crystal 중 선택)
   - 예제에서 사용할 기본 스타일(링크 스타일, 컴포넌트 디자인 정책) 설정 지점 정리

3. 편집기 화면 구성(“Figma clone” 최소 UI)
   - `Scaffold` 기반 3패널 레이아웃
     - 좌측: 툴 선택(Select / Rectangle / Oval / Connector)
     - 중앙: `FlexiEditor(flexiEditorContext: …)` 배치
     - 우측: 선택된 요소 정보(타입/ID/위치/크기 등 가능한 범위)
   - 상단 바: 현재 툴 표시, 줌 레벨 표시, 간단한 버튼(Reset view 등)

4. 도구(Tool) 동작 연결
   - “Rectangle/Oval” 툴: 캔버스 클릭/드래그로 컴포넌트 생성(가능한 정책/Writer API 활용)
   - “Select” 툴: 기본 선택/다중 선택(드래그 셀렉션은 `FlexiEditor` 콜백 활용)
   - “Connector” 툴: 컴포넌트 간 연결 생성(가능한 API 범위에서; 어려우면 최소로 링크 생성 버튼 제공)
   - 삭제/취소: 키보드 이벤트(`onKeyboardEvent`)와 캔버스 이벤트를 연결해 기본 삭제(Del/Backspace) 제공

5. Web 입력/단축키 보강
   - 휠/트랙패드 입력이 자연스럽게 동작하도록 캔버스 포인터 시그널 경로 확인 및 정책 적용
   - 필수 단축키만 제공: Delete, Escape(툴 취소/선택 해제), Ctrl/Cmd + 0(뷰 리셋 정도)

6. 검증 및 문서화(예제 실행 안내)
   - `example/`에서 Web 실행 확인(Chrome)
   - 최소 시나리오 테스트
     - 사각형/타원 생성 → 이동 → 선택 → 삭제
     - 줌/패닝 동작
     - 링크 생성/편집(구현 범위 내)
   - `example/README` 또는 루트 README에 예제 실행 방법 간단히 추가(요청 범위 내에서만)

## 성공 기준(검증 가능한 형태)
- `example/`가 존재하고 `flutter run -d chrome`으로 실행된다.
- 중앙 캔버스에서 도형을 생성/이동/선택/삭제할 수 있다.
- 마우스 휠/트랙패드 입력으로 줌 또는 패닝이 가능하다(정책이 제공하는 동작에 맞춰 일관되게).
- 예제 앱이 `flexi_editor`를 “플러그인처럼” 실제로 사용하고 있음을 코드로 확인할 수 있다.

