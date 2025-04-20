import 'package:flutter/material.dart';
import 'item.dart';

/// 裝備欄位系統：管理玩家的裝備
class Equipment {
  // 裝備槽位定義
  final Map<String, Item?> slots = {
    'weapon': null, // 武器
    'helmet': null, // 頭盔
    'armor': null, // 胸甲
    'gloves': null, // 手套
    'boots': null, // 鞋子
    'amulet': null, // 護符
    'ring': null, // 戒指
  };

  // 裝備類型與對應槽位的映射
  final Map<String, String> typeToSlot = {
    'weapon': 'weapon',
    'helmet': 'helmet',
    'armor': 'armor',
    'gloves': 'gloves',
    'boots': 'boots',
    'amulet': 'amulet',
    'ring': 'ring',
  };

  /// 裝備物品
  bool equip(Item item) {
    // 檢查物品是否可裝備
    if (!item.isEquippable) return false;

    // 獲取對應槽位
    final slotName = typeToSlot[item.equipType];
    if (slotName == null) return false;

    // 裝備物品
    slots[slotName] = item;
    return true;
  }

  /// 卸下裝備
  Item? unequip(String slotName) {
    final item = slots[slotName];
    if (item != null) {
      slots[slotName] = null;
    }
    return item;
  }

  /// 獲取裝備加成總和
  Map<String, double> getTotalStats() {
    final stats = <String, double>{
      'attack': 0,
      'defense': 0,
      'speed': 0,
      'maxHealth': 0,
      'maxMana': 0,
    };

    // 累加所有裝備的屬性
    slots.values.forEach((item) {
      if (item != null && item.stats != null) {
        item.stats!.forEach((key, value) {
          stats[key] = (stats[key] ?? 0) + value;
        });
      }
    });

    return stats;
  }

  /// 檢查指定類型的裝備是否已裝備
  bool isEquipped(String equipType) {
    final slotName = typeToSlot[equipType];
    if (slotName == null) return false;
    return slots[slotName] != null;
  }

  /// 獲取指定槽位的裝備
  Item? getEquippedItem(String slotName) {
    return slots[slotName];
  }
}
