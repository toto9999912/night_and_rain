// filepath: d:\game\night_and_rain\lib\weapon.dart
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'main.dart';

// 武器基礎類別
abstract class Weapon {
  final String name;
  final double damage;
  final double fireRate; // 發射間隔，以秒為單位
  final double bulletSpeed;
  final Color bulletColor;
  final Vector2 bulletSize;

  // 冷卻計時器
  double _cooldownTimer = 0.0;

  Weapon({
    required this.name,
    required this.damage,
    required this.fireRate,
    required this.bulletSpeed,
    required this.bulletColor,
    required this.bulletSize,
  });

  // 檢查武器是否可以發射
  bool canShoot() => _cooldownTimer <= 0;

  // 更新武器冷卻時間
  void update(double dt) {
    if (_cooldownTimer > 0) {
      _cooldownTimer -= dt;
    }
  }

  // 發射武器，返回是否成功發射（考慮冷卻時間）
  bool shoot(Vector2 position, double angle, NightAndRainGame gameRef) {
    if (canShoot()) {
      _performShoot(position, angle, gameRef);
      _cooldownTimer = fireRate;
      return true;
    }
    return false;
  }

  // 由子類實現的武器發射邏輯
  void _performShoot(Vector2 position, double angle, NightAndRainGame gameRef);
}

// 手槍 - 基本武器
class Pistol extends Weapon {
  Pistol()
    : super(
        name: '手槍',
        damage: 10.0,
        fireRate: 0.3,
        bulletSpeed: 500.0,
        bulletColor: Colors.amberAccent,
        bulletSize: Vector2(16, 8),
      );

  @override
  void _performShoot(Vector2 position, double angle, NightAndRainGame gameRef) {
    final bulletDirection = Vector2(math.cos(angle), math.sin(angle));
    final bulletOffset = 32.0; // 從玩家中心到邊緣的偏移
    final bulletPosition = position + bulletDirection * bulletOffset;

    gameRef.gameWorld.addBullet(
      bulletPosition,
      bulletDirection,
      bulletSpeed,
      damage,
      bulletColor: bulletColor,
      bulletSize: bulletSize,
    );
  }
}

// 散彈槍 - 一次發射多個子彈
class Shotgun extends Weapon {
  final int pelletCount; // 每次發射的彈丸數量
  final double spreadAngle; // 散射角度（弧度）

  Shotgun()
    : pelletCount = 5,
      spreadAngle = 0.3,
      super(
        name: '散彈槍',
        damage: 5.0, // 每個彈丸的傷害
        fireRate: 0.8, // 發射間隔較長
        bulletSpeed: 450.0,
        bulletColor: Colors.redAccent,
        bulletSize: Vector2(12, 6),
      );

  @override
  void _performShoot(Vector2 position, double angle, NightAndRainGame gameRef) {
    final bulletOffset = 32.0;
    final bulletPosition =
        position + Vector2(math.cos(angle), math.sin(angle)) * bulletOffset;

    // 計算散射角度
    for (int i = 0; i < pelletCount; i++) {
      final spreadFactor =
          -spreadAngle / 2 + (spreadAngle / (pelletCount - 1)) * i;
      final adjustedAngle = angle + spreadFactor;
      final bulletDirection = Vector2(
        math.cos(adjustedAngle),
        math.sin(adjustedAngle),
      );

      gameRef.gameWorld.addBullet(
        bulletPosition,
        bulletDirection,
        bulletSpeed,
        damage,
        bulletColor: bulletColor,
        bulletSize: bulletSize,
      );
    }
  }
}

// 機關槍 - 高射速
class MachineGun extends Weapon {
  MachineGun()
    : super(
        name: '機關槍',
        damage: 7.0,
        fireRate: 0.1, // 高射速
        bulletSpeed: 550.0,
        bulletColor: Colors.greenAccent,
        bulletSize: Vector2(14, 7),
      );

  @override
  void _performShoot(Vector2 position, double angle, NightAndRainGame gameRef) {
    // 略微隨機散射
    final randomSpread = (math.Random().nextDouble() - 0.5) * 0.1;
    final adjustedAngle = angle + randomSpread;
    final bulletDirection = Vector2(
      math.cos(adjustedAngle),
      math.sin(adjustedAngle),
    );

    final bulletOffset = 32.0;
    final bulletPosition = position + bulletDirection * bulletOffset;

    gameRef.gameWorld.addBullet(
      bulletPosition,
      bulletDirection,
      bulletSpeed,
      damage,
      bulletColor: bulletColor,
      bulletSize: bulletSize,
    );
  }
}
