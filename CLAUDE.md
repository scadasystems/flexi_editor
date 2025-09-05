# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

FlexiEditor는 상호작용하는 다이어그램, 플로차트, 노드 기반 인터페이스를 생성하는 유연한 시각 편집기를 제공하는 Flutter 플러그인입니다.

## 개발 명령어

`print()` 대신 `debugPrint()`를 사용하세요.

```bash
# 의존성 가져오기
flutter pub get

# 정적 분석
flutter analyze

# 코드 포맷팅
dart format .

# 플러그인 빌드
flutter build
```

참고: 이 프로젝트에는 현재 테스트 파일이나 테스트 스크립트가 구성되어 있지 않습니다.

## 핵심 아키텍처

### 정책 기반 아키텍처
이 플러그인은 믹스인을 통해 확장 가능한 동작을 허용하는 정교한 정책 기반 아키텍처를 사용합니다:

- **FlexiEditorContext**: 캔버스 모델, 상태, 이벤트를 관리하는 중앙 오케스트레이터
- **PolicySet**: 믹스인을 사용하여 동작 정책을 집계 (BasePolicySet이 기반 제공)
- **데이터 모델**: ComponentData<T>, LinkData<T>, FlexiData는 제네릭 사용자 정의 데이터 지원

### 주요 디렉토리 구조
- `lib/src/abstraction_layer/`: 정책 시스템 및 기본 추상화
- `lib/src/canvas_context/`: 핵심 컨텍스트, 데이터 모델, 이벤트
- `lib/src/widget/`: 주요 위젯 (FlexiEditor, FlexiEditorCanvas, 컴포넌트)
- `lib/src/utils/`: 유틸리티, 페인터, 스타일링 도우미

### 메인 엔트리 포인트
- **공용 API**: `lib/flexi_editor.dart` (35개 이상의 클래스 내보냄)
- **주요 위젯**: `FlexiEditor` (FlexiEditorContext 필요)
- **캔버스 구현**: `FlexiEditorCanvas` (제스처 및 렌더링 처리)

## 아키텍처 패턴

### 상태 관리
- Provider 패턴을 사용한 상태 관리
- 정책 추상화를 통한 캔버스 작업을 위한 Reader/Writer 패턴
- 다중 생성자 패턴을 통한 컨텍스트 공유

### 데이터 플로우
1. FlexiEditorContext는 모델, 상태, 이벤트를 오케스트레이션
2. PolicySet는 믹스인을 통해 확장 가능한 동작을 정의
3. 캔버스 위젯은 제스처를 처리하고 컴포넌트/링크를 렌더링
4. 데이터 모델은 지속성을 위한 JSON 직렬화를 지원

### 컴포넌트 시스템
- **Component**: 크기, 연결, 사용자 정의 데이터가 포함된 위치 지정된 컴포넌트
- **LinkData**: 스타일링 및 중간점이 있는 컴포넌트 간 연결
- **Z-order 렌더링**: 선택 상태에 따라 렌더링되는 컴포넌트

### 컨텍스트 생성 패턴
FlexiEditorContext는 4가지 생성 패턴을 지원합니다:
- **기본**: 새로운 모델과 상태
- **withSharedModel**: 모델 공유, 새로운 상태
- **withSharedState**: 새로운 모델, 상태 공유
- **withSharedModelAndState**: 모델과 상태 모두 공유

### PolicySet 믹스인 시스템
PolicySet는 15개의 믹스인을 통해 모든 에디터 동작을 정의합니다:
- **InitPolicy**: 에디터 초기화
- **CanvasPolicy**: 캔버스 수준 동작
- **ComponentPolicy/ComponentDesignPolicy/ComponentWidgetsPolicy**: 컴포넌트 관련 정책
- **LinkPolicy/LinkJointPolicy/LinkAttachmentPolicy/LinkWidgetsPolicy**: 링크 관련 정책
- **CanvasWidgetsPolicy**: 캔버스 위젯 관련 정책

## 주요 의존성
- `defer_pointer: ^0.0.2`: 고급 포인터 이벤트 처리
- `provider: ^6.1.5`: 상태 관리
- `uuid: ^4.5.1`: 고유 ID 생성

## 개발 참고사항
- 기존 테스트 없음 - 테스트 프레임워크 구축 필요
- 예시 디렉토리 최근 제거됨
- 엔터프라이즈급 확장성을 위해 설계된 플러그인
- 팬, 스케일, 탭, 드래그 선택을 포함한 고급 제스처 처리 지원
- 키보드 단축키 지원 (팬 모드용 스페이스바)