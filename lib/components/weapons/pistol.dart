import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:night_and_rain/main.dart';
import '../enums/item_rarity.dart';

import 'weapon.dart';

/// 手槍 - 基本武器
class Pistol extends Weapon {
  Pistol({super.rarity})
    : super(
        name: '手槍',
        damage: 10.0 * _getRarityMultiplier(rarity),
        fireRate: 0.3,
        bulletSpeed: 500.0,
        bulletColor: Colors.amberAccent,
        bulletSize: Vector2(16, 8),
      );

  @override
  void performShoot(Vector2 position, double angle, NightAndRainGame gameRef) {
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
}
