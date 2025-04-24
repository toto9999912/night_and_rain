import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../components/enums/item_type.dart';
import '../components/items/inventory.dart';
import '../components/items/equipment.dart';
import '../components/items/weapon_item.dart';

class InventoryUIController {
  final NightAndRainGame game;
  final Inventory inventory;
  final Equipment equipment;

  // UI 狀態 (仍需在控制器中保存，但只限業務邏輯相關的狀態)
  bool isVisible = false;
  int? selectedItemIndex;
  String? selectedEquipSlot;

  // 移除熱鍵綁定相關狀態，不再需要綁定模式
  // bool isBindingHotkey = false;
  // int? bindingItemIndex;

  InventoryUIController({
    required this.game,
    required this.inventory,
    required this.equipment,
  });

  /// 選擇背包中的物品
  void selectItem(int? index) {
    selectedItemIndex = index;
    // 移除綁定狀態相關邏輯，只保留物品選擇
    if (index != null) {
      debugPrint("【調試】選中物品，索引: $selectedItemIndex");
    }
  }

  // 移除toggleBindingMode方法，不再需要切換綁定模式

  /// 將選中的物品綁定到指定熱鍵槽位
  bool bindSelectedItemToHotkey(int hotkeySlot) {
    if (selectedItemIndex == null ||
        selectedItemIndex! >= inventory.items.length) {
      debugPrint("【調試】綁定失敗：無效的物品索引 $selectedItemIndex");
      return false;
    }

    final item = inventory.items[selectedItemIndex!];
    debugPrint("【調試】直接綁定物品到熱鍵槽 $hotkeySlot");
    debugPrint("【調試】嘗試綁定物品: ${item.name}，類型: ${item.type}，到熱鍵槽: $hotkeySlot");

    // 獲取HotkeysHud實例
    final hotkeysHud = game.hotkeysHud;

    if (item.type == ItemType.weapon) {
      // 武器物品，直接綁定而不檢查是否已裝備
      final weaponItem = item as WeaponItem;
      debugPrint("【調試】武器類型: ${weaponItem.weapon.runtimeType}");

      // 直接綁定武器到熱鍵，不需要先裝備
      debugPrint("【調試】直接綁定武器 ${weaponItem.name} 到熱鍵槽 $hotkeySlot");

      // 新方法：直接綁定武器物品而不是武器實例
      hotkeysHud.setWeaponItemHotkey(hotkeySlot, weaponItem);
      _showBindSuccessMessage(item.name, hotkeySlot);
      return true;
    } else {
      // 如果是消耗品或其他類型物品，直接添加到熱鍵
      debugPrint("【調試】綁定消耗品 ${item.name} 到熱鍵槽 $hotkeySlot");
      hotkeysHud.setConsumableHotkey(hotkeySlot, item);
      _showBindSuccessMessage(item.name, hotkeySlot);
      return true;
    }
  }

  /// 處理背包內物品的使用或裝備
  bool useSelectedItem() {
    if (selectedItemIndex != null &&
        selectedItemIndex! < inventory.items.length) {
      final item = inventory.items[selectedItemIndex!];

      // 根據物品類型決定是使用還是裝備
      if (item.isEquippable) {
        // 如果是裝備類型的物品，嘗試裝備
        final success = game.player.equipItem(selectedItemIndex!);
        if (success) {
          _showMessage("已裝備 ${item.name}");
          return true;
        } else {
          _showMessage("無法裝備 ${item.name}");
          return false;
        }
      } else {
        // 如果是消耗品或其他類型，直接使用
        final success = inventory.useItem(selectedItemIndex!);
        if (success) {
          _showMessage("已使用 ${item.name}");
        }
        return success;
      }
    }
    return false;
  }

  /// 處理鍵盤事件，返回是否已處理
  bool handleKeyEvent(LogicalKeyboardKey key, bool isKeyDown) {
    if (!isVisible) return false;

    if (isKeyDown) {
      // 處理 E 鍵 - 直接使用或裝備選中的物品
      if (key == LogicalKeyboardKey.keyE && selectedItemIndex != null) {
        debugPrint("【調試】按下 E 鍵，嘗試使用或裝備物品");
        useSelectedItem();
        return true;
      }

      // 數字鍵處理 (1-4) - 直接綁定選中的物品到熱鍵
      final keyNumber = _getNumberFromKey(key);
      if (keyNumber != null &&
          keyNumber >= 1 &&
          keyNumber <= 4 &&
          selectedItemIndex != null &&
          selectedItemIndex! < inventory.items.length) {
        final hotkeySlot = keyNumber - 1; // 轉換為0-3的索引
        bindSelectedItemToHotkey(hotkeySlot);
        return true;
      }

      // 一般模式 - 使用數字鍵5-9快速使用物品 (保留原功能)
      if (keyNumber != null &&
          keyNumber > 4 &&
          keyNumber <= 9 &&
          keyNumber - 5 < inventory.items.length) {
        debugPrint("【調試】使用物品索引: ${keyNumber - 5}");
        inventory.useItem(keyNumber - 5);
        return true;
      }
    }

    return true;
  }

  /// 顯示成功綁定的消息
  void _showBindSuccessMessage(String itemName, int hotkeySlot) {
    _showMessage("已將 $itemName 綁定至熱鍵 ${hotkeySlot + 1}");
  }

  /// 顯示消息
  void _showMessage(String message) {
    game.showMessage(message);
  }

  /// 從按鍵獲取數字（1-9）
  int? _getNumberFromKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit1) return 1;
    if (key == LogicalKeyboardKey.digit2) return 2;
    if (key == LogicalKeyboardKey.digit3) return 3;
    if (key == LogicalKeyboardKey.digit4) return 4;
    if (key == LogicalKeyboardKey.digit5) return 5;
    if (key == LogicalKeyboardKey.digit6) return 6;
    if (key == LogicalKeyboardKey.digit7) return 7;
    if (key == LogicalKeyboardKey.digit8) return 8;
    if (key == LogicalKeyboardKey.digit9) return 9;
    return null;
  }

  /// 打開背包
  void open() {
    isVisible = true;
  }

  /// 關閉背包
  void close() {
    isVisible = false;
    selectedItemIndex = null;
    // 移除綁定狀態相關字段
    // isBindingHotkey = false;
    // bindingItemIndex = null;
  }

  /// 切換背包開關狀態
  void toggle() {
    isVisible ? close() : open();
  }
}
