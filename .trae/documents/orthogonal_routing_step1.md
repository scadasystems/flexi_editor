# 직교 라우팅 재구현 계획 (4x4 포트 대응)

## 목표
- 기존 직교 라우팅 로직을 완전히 삭제하고, 4x4 포트 조합(16가지 경우)을 체계적으로 처리하는 새로운 알고리즘으로 대체합니다.
- 사용자의 요청대로 **"좌측 컴포넌트(A)의 우측 포트 -> 우측 컴포넌트(B)의 좌측 포트"** 경우부터 차례대로 구현합니다.
- 목적지 화살표가 반드시 표시되어야 하므로 직교 라우팅인 경우, Gap 이 있어야 합니다.

## 접근 방식
- **Port-to-Port Case Analysis**: 시작 포트와 끝 포트의 조합에 따라 최적의 경로 전략을 선택합니다.
- **상대적 위치 고려**: 컴포넌트 A와 B의 위치 관계(A가 B의 왼쪽에 있는지, 위에 있는지 등)에 따라 세부 경로가 달라집니다.
- **단계적 구현**:
    1.  **Case 1**: A(Right) -> B(Left) (가장 일반적인 순방향 연결)
    2.  이후 다른 케이스들 순차적 추가 (A(Right)->B(Right), A(Bottom)->B(Top) 등)

## 구현 상세 (Step 1: A(Right) -> B(Left))

### 시나리오 분석
- **Normal Case**: B가 A의 오른쪽에 있고, 수직 위치가 비슷함.
    - 경로: A(Right) -> 중간지점 -> B(Left)
    - 형태: 직선 또는 곡선 형태 (코너 없음)
- **Vertical Offset Case**: B가 A보다 많이 위/아래에 있음.
    - 경로: A(Right) -> 중간 수직선 -> B(Left)
    - 형태: 'Z' 형태 (코너 2개)
- **Overlap/Backward Case**: B가 A의 왼쪽에 있거나 겹침.
    - 경로: A(Right) -> 우측 공간으로 이동 -> 수직 이동 -> B(Left) 앞 공간으로 이동 -> B(Left)
    - 형태: 'U' 형태 또는 복잡한 'Z' (코너 4개)

### 알고리즘 구조
`LinkRouter` 클래스를 리팩토링합니다.
1.  `getOrthogonalPath` 메서드 초기화 (기존 로직 삭제).
2.  `_routeRightToLeft` 메서드 구현.
3.  Stubbing(돌출)은 기본적으로 적용.

### 코드 구조
```dart
class LinkRouter {
  static List<Offset> getOrthogonalPath(...) {
    // 1. Stubbing
    // 2. 포트 조합에 따른 분기
    if (startPort == PortType.right && endPort == PortType.left) {
      return _routeRightToLeft(...);
    }
    // ... 다른 케이스들 (일단 기본 Fallback 또는 빈 리스트)
    return []; 
  }

  static List<Offset> _routeRightToLeft(...) {
    // 1. A가 B의 왼쪽에 있는 경우 (Normal)
    if (p1.dx < p2.dx) {
      // 중간 X 지점 계산
      double midX = (p1.dx + p2.dx) / 2;
      return [p1, Offset(midX, p1.dy), Offset(midX, p2.dy), p2];
    }
    // 2. A가 B의 오른쪽에 있는 경우 (Backward)
    else {
      // A의 오른쪽으로 더 나가고, B의 왼쪽으로 더 나가서 'ㄷ'자 2개를 합친 형태?
      // A -> Right -> Down/Up -> Left -> Down/Up -> Right -> B
      // 더 간단하게: A와 B의 사이(Y축)를 통과할 수 있으면 통과, 아니면 외곽 우회.
      
      // 전략: Y축 중간 지점으로 이동
      double midY = (p1.dy + p2.dy) / 2;
      return [
        p1, 
        Offset(p1.dx, midY), // 여기서 바로 꺾으면 컴포넌트 뚫을 수 있음. 
        // Backward는 좀 더 복잡하므로 Step 1에서는 Normal Case에 집중.
      ];
    }
  }
}
```

## Todo List
- [ ] `LinkRouter.getOrthogonalPath`의 기존 로직 삭제 및 스켈레톤 작성.
- [ ] `_routeRightToLeft` (A:Right -> B:Left) 구현.
    - [ ] Normal Case (A가 B 왼쪽): Mid-X Vertical Segment (Z-Shape).
    - [ ] Backward Case (A가 B 오른쪽): 3-Corner or 5-Corner Strategy (추후 정교화).
