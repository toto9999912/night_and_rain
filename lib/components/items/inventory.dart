// filepath: d:\game\night_and_rain\lib\items\inventory.dart
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../player.dart';
import '../enums/item_type.dart';
import 'item.dart';
import 'weapon_item.dart';

/// 背包系統類
class Inventory {
  final List<Item> items = []; // 背包中的物品
  final int maxSize; // 背包最大容量
  bool isOpen = false; // 背包是否開啟
  final Player player; // 關聯的玩家實例

  // 背包變動後的回調函數
  Function? onInventoryChanged;

  Inventory({required this.player, this.maxSize = 20});

  /// 檢查背包是否已滿
  bool get isFull => items.length >= maxSize;

  /// 取得背包中物品數量
  int get itemCount => items.length;

  /// 添加物品到背包
  /// 如果物品可堆疊，會嘗試與現有物品堆疊
  /// 返回是否成功添加
  bool addItem(Item item) {
    bool changed = false;

    // 如果背包已滿且無法堆疊，則不添加
    if (isFull && !_canStack(item)) return false;

    // 先嘗試堆疊
    if (item.isStackable) {
      final existingItem = items.firstWhereOrNull(
        (i) => i.id == item.id && i.quantity < i.maxStackSize,
      );

      if (existingItem != null) {
        // 計算能夠堆疊的數量
        final spaceLeft = existingItem.maxStackSize - existingItem.quantity;
        final stackAmount = min(spaceLeft, item.quantity);

        existingItem.quantity += stackAmount;
        item.quantity -= stackAmount;
        changed = true;

        // 如果還有剩餘，且背包未滿，則添加新物品
        if (item.quantity > 0 && !isFull) {
          final newItem = item.copyWith();
          items.add(newItem);
        }
      }
    }

    // 如果無法堆疊或找不到相同物品，則添加新物品
    if (!changed && !isFull) {
      final newItem = item.copyWith();
      items.add(newItem);
      changed = true;
    }

    // 如果背包有變動，通知更新熱鍵系統
    if (changed) {
      _notifyInventoryChanged();
    }

    // 如果是武器物品，更新戰鬥系統
    if (changed && item is WeaponItem) {
      player.inventory.syncWeaponsWithCombatSystem();
    }

    return changed;
  }

  /// 從背包中移除物品
  bool removeItem(String itemId, {int quantity = 1}) {
    // 找到對應物品
    final itemIndex = items.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return false;

    final item = items[itemIndex];
    bool changed = false;

    // 如果移除數量小於物品數量
    if (quantity < item.quantity) {
      item.quantity -= quantity;
      changed = true;
    }
    // 如果移除數量大於或等於物品數量，則移除整個物品
    else {
      items.removeAt(itemIndex);
      changed = true;
    }

    // 如果背包有變動，通知更新熱鍵系統
    if (changed) {
      _notifyInventoryChanged();
    }

    return changed;
  }

  /// 從背包中移除指定索引的物品
  bool removeItemAt(int index) {
    if (index < 0 || index >= items.length) return false;
    bool isWeapon = items[index] is WeaponItem;
    items.removeAt(index);

    // 如果移除的是武器，更新戰鬥系統
    if (isWeapon) {
      player.inventory.syncWeaponsWithCombatSystem();
    }

    // 通知更新熱鍵系統
    _notifyInventoryChanged();

    return true;
  }

  /// 使用指定位置的物品
  bool useItem(int index) {
    if (index < 0 || index >= items.length) return false;

    final item = items[index];
    final result = item.use(player);

    // 如果使用成功且數量為0，則移除物品
    if (result && item.quantity <= 0) {
      items.removeAt(index);

      // 物品被移除，通知熱鍵系統
      _notifyInventoryChanged();
    } else if (result) {
      // 物品數量變更，也通知熱鍵系統
      _notifyInventoryChanged();
    }

    return result;
  }

  /// 根據類型過濾物品
  List<Item> filterByType(ItemType type) {
    return items.where((item) => item.type == type).toList();
  }

  /// 清空背包
  void clear() {
    items.clear();

    // 清空背包後通知熱鍵系統
    _notifyInventoryChanged();
  }

  /// 檢查物品是否可以堆疊
  bool _canStack(Item newItem) {
    if (!newItem.isStackable) return false;

    return items.any(
      (item) => item.id == newItem.id && item.quantity < item.maxStackSize,
    );
  }

  /// 通知背包變動
  void _notifyInventoryChanged() {
    try {
      // 調用背包變動回調
      if (onInventoryChanged != null) {
        onInventoryChanged!();
      }

      // 直接更新熱鍵系統
      player.game.hotkeysHud.updateWeaponReferences();
    } catch (e) {
      debugPrint("【錯誤】通知背包變動時出錯: $e");
    }
  }
}
