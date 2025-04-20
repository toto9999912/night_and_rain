import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:night_and_rain/main.dart';

import '../enums/item_rarity.dart';

/// 武器基礎類別
abstract class Weapon {
  final String name;
  final double damage;
  final double fireRate; // 發射間隔，以秒為單位
  final double bulletSpeed;
  final Color bulletColor;
  final Vector2 bulletSize;
  final ItemRarity rarity; // 添加稀有度屬性

  // 冷卻計時器
  double _cooldownTimer = 0.0;

  Weapon({
    required this.name,
    required this.damage,
    required this.fireRate,
    required this.bulletSpeed,
    required this.bulletColor,
    required this.bulletSize,
    this.rarity = ItemRarity.common,
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
      performShoot(position, angle, gameRef);
      _cooldownTimer = fireRate;
      return true;
    }
    return false;
  }

  // 由子類實現的武器發射邏輯
  void performShoot(Vector2 position, double angle, NightAndRainGame gameRef);

  // 創建武器的簡單描述
  String getDescription() {
    return '傷害: ${damage.toStringAsFixed(1)}, 射速: ${(1 / fireRate).toStringAsFixed(1)}發/秒';
  }
}
