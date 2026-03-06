# Flexi Editor Example (Figma Clone Web)

이 앱은 `flexi_editor` 패키지를 사용해 웹에서 동작하는 간단한 “Figma 스타일” 캔버스 편집기를 제공합니다.

## 실행

```bash
cd example
flutter pub get
flutter run -d chrome
```

## 웹 빌드

```bash
cd example
flutter build web
```

## 사용 방법

- 좌측 툴바
  - Select: 선택/이동
    - 모서리 핸들 드래그: 크기 조절
    - 상단 원형 핸들 드래그: 회전
  - Rectangle / Oval: 드래그로 도형 생성
  - Connector: 도형 2개를 클릭해 링크 생성
- 줌/패닝
  - 마우스 휠: 줌
  - Space 누른 채 드래그: 패닝
  - 상단 Reset 또는 Ctrl/Cmd + 0: 뷰 리셋
- 삭제
  - Delete/Backspace: 선택된 도형/링크 삭제
