import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

class OrthogonalPathFinder {
  static const double gridSize = 20.0;
  static const double obstaclePadding = 10.0;

  /// 경로 탐색
  /// [start]: 시작점 (Global or Canvas Coordinate)
  /// [end]: 끝점
  /// [obstacles]: 장애물 리스트 (컴포넌트 영역)
  /// [canvasRect]: 캔버스 전체 영역 (탐색 범위 제한용, 선택적)
  static List<Offset> findPath(
    Offset start,
    Offset end,
    List<Rect> obstacles, {
    Rect? canvasRect,
  }) {
    // 1. 시작점과 끝점을 그리드 좌표로 변환
    final startNode = _toGrid(start);
    final endNode = _toGrid(end);

    // 2. 탐색 범위 설정 (최적화를 위해 시작/끝점 주변으로 제한할 수도 있음)
    // 여기서는 동적으로 확장하거나 충분히 큰 범위를 잡습니다.
    // 간단하게 obstacles와 start, end를 모두 포함하는 영역을 구합니다.
    Rect bounds = Rect.fromPoints(start, end);
    
    // 시작점과 끝점을 포함하는 영역을 기준으로 장애물 필터링
    // 전체 장애물을 순회하는 비용을 줄이기 위해, 
    // 탐색 범위 내에 있는 장애물만 고려하도록 할 수도 있으나,
    // 현재는 모든 장애물을 포함하도록 범위를 확장하는 방식을 사용 중.
    // 최적화: 탐색 범위를 너무 크게 잡지 않고, 시작/끝점 주변으로 제한하되
    // 그 경로 상에 있는 장애물만 피하도록 하는 것이 좋음.
    
    // 여기서는 일단 시작/끝점을 포함하는 사각형에 여유를 둔 영역을 탐색 범위로 설정
    bounds = bounds.inflate(gridSize * 10); // 여유 공간 충분히 확보

    final int minX = (bounds.left / gridSize).floor();
    final int maxX = (bounds.right / gridSize).ceil();
    final int minY = (bounds.top / gridSize).floor();
    final int maxY = (bounds.bottom / gridSize).ceil();

    // 3. A* 알고리즘 준비
    final openList = PriorityQueue<_Node>((a, b) => a.f.compareTo(b.f));
    final closedSet = <Point<int>>{};
    final cameFrom = <Point<int>, _Node>{};

    final startNodeObj = _Node(startNode, 0, _heuristic(startNode, endNode), null);
    openList.add(startNodeObj);
    cameFrom[startNode] = startNodeObj;

    // 장애물 그리드 매핑 (성능을 위해 필요할 때 검사하는 방식 사용)
    // 미리 맵을 만들지 않고 isWalkable 함수에서 검사

    while (openList.isNotEmpty) {
      final current = openList.removeFirst();

      if (current.position == endNode) {
        return _reconstructPath(current, start, end);
      }

      closedSet.add(current.position);

      // 상하좌우 이웃 탐색
      final neighbors = [
        Point(current.position.x, current.position.y - 1), // 상
        Point(current.position.x, current.position.y + 1), // 하
        Point(current.position.x - 1, current.position.y), // 좌
        Point(current.position.x + 1, current.position.y), // 우
      ];

      for (final neighbor in neighbors) {
        if (closedSet.contains(neighbor)) continue;

        // 범위 체크
        if (neighbor.x < minX ||
            neighbor.x > maxX ||
            neighbor.y < minY ||
            neighbor.y > maxY) {
          continue;
        }

        // 장애물 체크
        if (!_isWalkable(neighbor, obstacles, startNode, endNode)) {
          continue;
        }

        // 비용 계산
        // 방향 전환 페널티
        double turnCost = 0;
        if (current.parent != null) {
          final prevDirection = current.position - current.parent!.position;
          final newDirection = neighbor - current.position;
          if (prevDirection != newDirection) {
            turnCost = 5.0; // 방향 전환 비용
          }
        }

        final gScore = current.g + 1 + turnCost;
        final hScore = _heuristic(neighbor, endNode);
        final neighborNode = _Node(neighbor, gScore, hScore, current);

        // 이미 openList에 더 낮은 비용으로 있는지 확인해야 하지만,
        // PriorityQueue에서 찾기 어려우므로 그냥 추가하고 closedSet으로 중복 처리
        // (정석적인 A*는 openList 내의 노드 업데이트가 필요함)
        // 여기서는 간단하게 처리 (중복 방문 허용하되 closedSet으로 방어)
        
        // 더 나은 경로인지 확인
        if (!cameFrom.containsKey(neighbor) || gScore < cameFrom[neighbor]!.g) {
             cameFrom[neighbor] = neighborNode;
             openList.add(neighborNode);
        }
      }
    }

    // 경로를 찾지 못한 경우: 직선 경로 반환 (Fallback)
    // 또는 꺾은선으로 대충 연결
    return [start, Offset(start.dx, end.dy), end];
  }

  static Point<int> _toGrid(Offset point) {
    return Point((point.dx / gridSize).round(), (point.dy / gridSize).round());
  }

  static Offset _toPoint(Point<int> gridPoint) {
    return Offset(gridPoint.x * gridSize, gridPoint.y * gridSize);
  }

  static double _heuristic(Point<int> a, Point<int> b) {
    return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
  }

  static bool _isWalkable(
    Point<int> point,
    List<Rect> obstacles,
    Point<int> startNode,
    Point<int> endNode,
  ) {
    // 시작점과 끝점은 장애물이어도 통과 가능 (포트 위치가 컴포넌트 경계일 수 있음)
    if (point == startNode || point == endNode) return true;

    final rect = Rect.fromCenter(
      center: _toPoint(point),
      width: gridSize,
      height: gridSize,
    );

    // 약간의 여유를 두고 검사
    final checkRect = rect.deflate(2.0);

    for (final obs in obstacles) {
      // 장애물에 패딩을 적용한 영역
      final inflatedObs = obs.inflate(obstaclePadding);
      if (inflatedObs.overlaps(checkRect)) {
        return false;
      }
    }
    return true;
  }

  static List<Offset> _reconstructPath(
    _Node endNode,
    Offset originalStart,
    Offset originalEnd,
  ) {
    final path = <Offset>[];
    _Node? current = endNode;

    while (current != null) {
      path.add(_toPoint(current.position));
      current = current.parent;
    }

    // 역순이므로 뒤집기
    final reversedPath = path.reversed.toList();
    
    // 시작점과 끝점을 정확한 위치로 보정
    if (reversedPath.isNotEmpty) {
      reversedPath[0] = originalStart;
      reversedPath[reversedPath.length - 1] = originalEnd;
    }

    // 경로 단순화 (직선 구간 병합)
    return _simplifyPath(reversedPath);
  }

  static List<Offset> _simplifyPath(List<Offset> path) {
    if (path.length < 3) return path;

    final simplified = <Offset>[path[0]];
    Offset prevDir = _direction(path[0], path[1]);

    for (int i = 1; i < path.length - 1; i++) {
      final currentDir = _direction(path[i], path[i + 1]);
      // 방향이 바뀌면 점 추가
      // 부동 소수점 오차 고려
      if ((prevDir - currentDir).distance > 0.001) {
        simplified.add(path[i]);
        prevDir = currentDir;
      }
    }

    simplified.add(path.last);
    return simplified;
  }

  static Offset _direction(Offset a, Offset b) {
    final diff = b - a;
    if (diff.distance == 0) return Offset.zero;
    return diff / diff.distance;
  }
}

class _Node {
  final Point<int> position;
  final double g; // Cost from start
  final double h; // Heuristic to end
  final _Node? parent;

  double get f => g + h;

  _Node(this.position, this.g, this.h, this.parent);
}

/// PriorityQueue 구현 (collection 패키지 없으면 사용)
/// 간단한 Min Heap
class PriorityQueue<T> {
  final List<T> _heap = [];
  final int Function(T, T) comparator;

  PriorityQueue(this.comparator);

  bool get isNotEmpty => _heap.isNotEmpty;

  void add(T item) {
    _heap.add(item);
    _bubbleUp(_heap.length - 1);
  }

  T removeFirst() {
    if (_heap.isEmpty) throw StateError('Queue is empty');
    final result = _heap[0];
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _bubbleDown(0);
    }
    return result;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) ~/ 2;
      if (comparator(_heap[index], _heap[parentIndex]) < 0) {
        _swap(index, parentIndex);
        index = parentIndex;
      } else {
        break;
      }
    }
  }

  void _bubbleDown(int index) {
    while (true) {
      final leftChild = 2 * index + 1;
      final rightChild = 2 * index + 2;
      int smallest = index;

      if (leftChild < _heap.length &&
          comparator(_heap[leftChild], _heap[smallest]) < 0) {
        smallest = leftChild;
      }

      if (rightChild < _heap.length &&
          comparator(_heap[rightChild], _heap[smallest]) < 0) {
        smallest = rightChild;
      }

      if (smallest != index) {
        _swap(index, smallest);
        index = smallest;
      } else {
        break;
      }
    }
  }

  void _swap(int i, int j) {
    final temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }
}
