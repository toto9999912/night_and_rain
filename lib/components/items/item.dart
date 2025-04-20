// filepath: d:\game\night_and_rain\lib\items\item.dart

import 'package:flutter/material.dart';

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

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.rarity = ItemRarity.common,
    this.maxStackSize = 1,
    this.quantity = 1,
    this.iconPath,
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

  /// 用於深度複製物品的方法
  Item copyWith({int? quantity});
}
