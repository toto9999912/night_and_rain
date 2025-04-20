// filepath: d:\game\night_and_rain\lib\items\item.dart

import 'package:flutter/material.dart';

import '../player.dart';
import '../weapon.dart';

/// 物品種類枚舉
enum ItemType {
  weapon, // 武器
  potion, // 藥水
  // 以後可以添加其他種類
  quest, // 任務道具
  equipment, // 裝備
  material, // 材料
}

/// 物品稀有度枚舉
enum ItemRarity {
  common, // 普通
  uncommon, // 不常見
  rare, // 稀有
  epic, // 史詩
  legendary, // 傳說
}

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

/// 武器物品類
class WeaponItem extends Item {
  final Weapon weapon; // 關聯的武器實例

  WeaponItem({
    required String id,
    required String name,
    required String description,
    required this.weapon,
    ItemRarity rarity = ItemRarity.common,
    String? iconPath,
  }) : super(
         id: id,
         name: name,
         description: description,
         type: ItemType.weapon,
         rarity: rarity,
         maxStackSize: 1, // 武器不可堆疊
         iconPath: iconPath,
       );

  @override
  bool use(Player player) {
    // 在玩家的武器列表中查找此武器
    final existingWeaponIndex = player.weapons.indexWhere(
      (w) => w.runtimeType == weapon.runtimeType,
    );

    if (existingWeaponIndex >= 0) {
      // 如果玩家已有此武器，則切換到該武器
      player.switchWeapon(existingWeaponIndex);
      return true;
    } else {
      // 如果玩家沒有此武器，則添加到武器列表並切換
      player.weapons.add(weapon);
      player.switchWeapon(player.weapons.length - 1);
      return true;
    }
  }

  @override
  Item copyWith({int? quantity}) {
    return WeaponItem(
      id: id,
      name: name,
      description: description,
      weapon: weapon,
      rarity: rarity,
      iconPath: iconPath,
    );
  }
}

/// 藥水物品類
class PotionItem extends Item {
  final int healthRestored; // 恢復生命值
  final int manaRestored; // 恢復魔法值
  final bool isBuff; // 是否為增益效果
  final Duration? buffDuration; // 增益效果持續時間

  PotionItem({
    required String id,
    required String name,
    required String description,
    this.healthRestored = 0,
    this.manaRestored = 0,
    this.isBuff = false,
    this.buffDuration,
    int maxStackSize = 5,
    int quantity = 1,
    ItemRarity rarity = ItemRarity.common,
    String? iconPath,
  }) : super(
         id: id,
         name: name,
         description: description,
         type: ItemType.potion,
         rarity: rarity,
         maxStackSize: maxStackSize,
         quantity: quantity,
         iconPath: iconPath,
       );

  @override
  bool use(Player player) {
    // 檢查是否需要使用該藥水
    bool shouldUse = false;

    // 如果是治療藥水但玩家已滿血，或是魔法藥水但玩家已滿魔力，則無需使用
    if ((healthRestored > 0 && player.currentHealth < player.maxHealth) ||
        (manaRestored > 0 && player.currentMana < player.maxMana) ||
        isBuff) {
      shouldUse = true;
    }

    if (shouldUse) {
      // 恢復生命值
      if (healthRestored > 0) {
        player.heal(healthRestored);
      }

      // 恢復魔法值
      if (manaRestored > 0) {
        player.restoreMana(manaRestored);
      }

      // TODO: 處理增益效果，可在未來版本實現
      if (isBuff && buffDuration != null) {
        // 應用增益效果的代碼
      }

      // 減少數量，如果數量為0，物品會被從背包中移除
      quantity--;
      return true;
    }

    return false;
  }

  @override
  Item copyWith({int? quantity}) {
    return PotionItem(
      id: id,
      name: name,
      description: description,
      healthRestored: healthRestored,
      manaRestored: manaRestored,
      isBuff: isBuff,
      buffDuration: buffDuration,
      maxStackSize: maxStackSize,
      quantity: quantity ?? this.quantity,
      rarity: rarity,
      iconPath: iconPath,
    );
  }
}
