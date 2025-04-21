import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../bullet.dart';

/// 專責管理遊戲中所有子彈相關功能的類別
class BulletManager {
  final List<Bullet> bullets = [];

  /// 添加子彈到遊戲世界
  Bullet createBullet(Vector2 position, Vector2 direction, double speed, double damage, {Color? bulletColor, Vector2? bulletSize}) {
    final bullet = Bullet(
      position: position,
      direction: direction.normalized(),
      speed: speed,
      damage: damage,
      bulletColor: bulletColor,
      bulletSize: bulletSize,
    );

    bullets.add(bullet);
    return bullet;
  }

  /// 清理已經標記為應移除的子彈
  void cleanupBullets() {
    bullets.where((b) => b.shouldRemove).toList().forEach((b) {
      b.removeFromParent();
      bullets.remove(b);
    });
  }

  /// 更新子彈
  void update(double dt) {
    cleanupBullets();
  }
}
