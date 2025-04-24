import 'item.dart';
import '../weapons/weapon.dart';
import 'weapon_item.dart';

/// 裝備欄位系統：管理玩家的裝備
class Equipment {
  // 裝備槽位定義
  final Map<String, Item?> slots = {
    'weapon': null, // 武器
    'armor': null, // 胸甲
  };

  // 裝備類型與對應槽位的映射
  final Map<String, String> typeToSlot = {'weapon': 'weapon', 'armor': 'armor'};

  /// 獲取當前裝備的武器
  Weapon? getCurrentWeapon() {
    final weaponItem = slots['weapon'] as WeaponItem?;
    return weaponItem?.weapon;
  }

  /// 獲取背包中的所有武器物品
  List<WeaponItem> getInventoryWeapons(List<Item> inventoryItems) {
    return inventoryItems.whereType<WeaponItem>().cast<WeaponItem>().toList();
  }

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
    for (var item in slots.values) {
      if (item != null && item.stats != null) {
        item.stats!.forEach((key, value) {
          stats[key] = (stats[key] ?? 0) + value;
        });
      }
    }

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
