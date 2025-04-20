import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:night_and_rain/components/enums/item_rarity.dart';
import 'package:night_and_rain/main.dart';

import 'weapon.dart';

/// 機關槍 - 高射速
class MachineGun extends Weapon {
  MachineGun({super.rarity})
    : super(
        name: '機關槍',
        damage: 7.0 * _getRarityMultiplier(rarity),
        fireRate: 0.1, // 高射速
        bulletSpeed: 550.0,
        bulletColor: Colors.greenAccent,
        bulletSize: Vector2(14, 7),
      );

  @override
  void performShoot(Vector2 position, double angle, NightAndRainGame gameRef) {
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
