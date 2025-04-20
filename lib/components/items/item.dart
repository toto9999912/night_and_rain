// filepath: d:\game\night_and_rain\lib\items\item.dart

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flame/sprite.dart';

import '../../player.dart';
import '../enums/item_rarity.dart';
import '../enums/item_type.dart';

/// 基礎物品類別
abstract class Item {
  final String id; // 物品唯一ID
  final String name; // 物品名稱
  final String description; // 物品描述
  final ItemType type; // 物品類型
  final ItemRarity rarity; // 物品稀有度
  final int maxStackSize; // 最大堆疊數量，1表示不可堆疊
  int quantity; // 當前數量
  final String? iconPath; // 物品圖標路徑

  // 裝備相關屬性
  final bool isEquippable; // 是否可裝備
  final String? equipType; // 裝備類型
  final Map<String, double>? stats; // 裝備屬性加成

  /// 精靈圖相關屬性
  final int spriteX; // 圖標在精靈圖中的X索引
  final int spriteY; // 圖標在精靈圖中的Y索引

  /// 精靈圖的大小
  static const int spriteSize = 24;

  /// 精靈圖的路徑
  static const String spriteSheetPath = 'assets/images/item_pack.png';

  Sprite? sprite; // 新增屬性：物品的精靈圖

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = ItemRarity.common,
    this.maxStackSize = 1,
    this.quantity = 1,
    this.iconPath,
    this.isEquippable = false,
    this.equipType,
    this.stats,
    required this.spriteX,
    required this.spriteY,
  });

  /// 物品是否可以堆疊
  bool get isStackable => maxStackSize > 1;

  /// 取得物品顏色（基於稀有度）
  Color get rarityColor {
    return switch (rarity) {
      ItemRarity.common => Colors.grey,
      ItemRarity.uncommon => Colors.green,
      ItemRarity.rare => Colors.blue,
      ItemRarity.epic => Colors.purple,
      ItemRarity.legendary => Colors.orange,
    };
  }

  /// 使用物品的抽象方法
  bool use(Player player);

  /// 裝備物品的方法
  bool equip(Player player) {
    if (!isEquippable) return false;
    return player.equipment.equip(this);
  }

  /// 卸下裝備的方法
  bool unequip(Player player) {
    if (!isEquippable) return false;
    return player.equipment.unequip(equipType!) != null;
  }

  /// 獲取屬性描述
  String getStatsDescription() {
    if (stats == null || stats!.isEmpty) return '';

    final List<String> statsList = [];
    stats!.forEach((key, value) {
      String sign = value > 0 ? '+' : '';
      String statName = key;
      switch (key) {
        case 'attack':
          statName = '攻擊力';
          break;
        case 'defense':
          statName = '防禦力';
          break;
        case 'speed':
          statName = '速度';
          break;
        case 'maxHealth':
          statName = '最大生命值';
          break;
        case 'maxMana':
          statName = '最大魔力值';
          break;
      }
      statsList.add('$statName: $sign${value.toStringAsFixed(1)}');
    });

    return statsList.join('\n');
  }

  /// 用於深度複製物品的方法
  Item copyWith({int? quantity});

  /// 獲取物品的精靈圖
  Future<Sprite> getSprite() async {
    final spriteSheet = SpriteSheet(
      image: await Flame.images.load(spriteSheetPath),
      srcSize: Vector2(spriteSize.toDouble(), spriteSize.toDouble()),
    );
    return spriteSheet.getSprite(spriteX, spriteY);
  }
}
