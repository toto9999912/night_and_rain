import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// 專門處理玩家移動的類別
class PlayerMovement {
  // 移動與物理參數
  final double moveSpeed;
  final double acceleration;
  final double deceleration;
  final double maxSpeed;
  final Vector2 mapSize;

  // 當前移動狀態
  Vector2 direction = Vector2.zero();
  Vector2 velocity = Vector2.zero();

  // 參考主組件
  final PositionComponent component;

  PlayerMovement({
    required this.component,
    required this.mapSize,
    this.moveSpeed = 200.0,
    this.acceleration = 1200.0,
    this.deceleration = 2400.0,
    this.maxSpeed = 300.0,
  });

  /// 更新移動物理
  void update(double dt) {
    // 平滑移動邏輯
    if (direction.length > 0) {
      velocity += direction * acceleration * dt;
      if (velocity.length > maxSpeed) {
        velocity.normalize();
        velocity *= maxSpeed;
      }
    } else {
      final slowDownAmount = deceleration * dt;
      velocity.length <= slowDownAmount
          ? velocity = Vector2.zero()
          : velocity -= velocity.normalized() * slowDownAmount;
    }

    // 更新位置並限制在地圖範圍內
    component.position += velocity * dt;
    component.position.clamp(
      Vector2.zero() + component.size / 2,
      mapSize - component.size / 2,
    );
  }

  /// 處理鍵盤輸入更新移動方向
  void handleInput(Set<LogicalKeyboardKey> keysPressed) {
    direction = Vector2.zero();

    // 移動控制
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y = 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x = 1;
    }

    if (direction.length > 0) {
      direction.normalize();
    }
  }

  /// 停止移動
  void stopMovement() {
    direction = Vector2.zero();
    velocity = Vector2.zero();
  }
}
