import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:night_and_rain/main.dart';
import '../enums/item_rarity.dart';
import 'weapon.dart';

/// 散彈槍 - 一次發射多個子彈
class Shotgun extends Weapon {
  final int pelletCount; // 每次發射的彈丸數量
  final double spreadAngle; // 散射角度（弧度）

  Shotgun({ItemRarity rarity = ItemRarity.common})
    : pelletCount = 5,
      spreadAngle = 0.3,
      super(
        name: '散彈槍',
        damage: 5.0 * _getRarityMultiplier(rarity), // 每個彈丸的傷害
        fireRate: 0.8, // 發射間隔較長
        bulletSpeed: 450.0,
        bulletColor: Colors.redAccent,
        bulletSize: Vector2(12, 6),
        rarity: rarity,
      );

  @override
  void performShoot(Vector2 position, double angle, NightAndRainGame gameRef) {
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

  // 根據稀有度提供不同的傷害倍率
  static double _getRarityMultiplier(ItemRarity rarity) {
    return switch (rarity) {
      ItemRarity.common => 1.0,
      ItemRarity.uncommon => 1.2,
      ItemRarity.rare => 1.5,
      ItemRarity.epic => 1.8,
      ItemRarity.legendary => 2.2,
    };
  }

  @override
  String getDescription() {
    return '傷害: ${damage.toStringAsFixed(1)} x $pelletCount, 射速: ${(1 / fireRate).toStringAsFixed(1)}發/秒';
  }
}
