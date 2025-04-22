import 'package:flame/components.dart';
import '../../main.dart';
import '../items/inventory.dart';
import '../items/equipment.dart';
import '../items/item.dart';
import '../enums/item_rarity.dart';
import '../items/potion_item.dart';
import '../items/weapon_item.dart';
import '../../ui/Inventory_ui.dart';
import '../../ui/character_panel.dart';
import '../../ui/dialogue_system.dart';

/// 專門處理玩家背包和裝備系統的類別
class PlayerInventory {
  // 背包系統
  late Inventory inventory;
  late Equipment equipment;
  late InventoryUI inventoryUI;
  late CharacterPanel characterPanel;
  late DialogueSystem dialogueSystem;

  // 參考遊戲主類
  final HasGameReference<NightAndRainGame> gameRef;
  final dynamic player; // 玩家引用，使用 dynamic 避免循環引用

  // 標記是否已初始化 UI 組件
  bool _uiInitialized = false;

  PlayerInventory({required this.gameRef, required this.player});

  /// 初始化背包系統
  void initInventory() {
    // 創建背包實例
    inventory = Inventory(player: player);

    // 添加初始物品
    _addStartingItems();
  }

  /// 初始化裝備系統
  void initEquipment() {
    equipment = Equipment();
  }

  /// 準備 UI 組件（創建實例但不添加到組件樹）
  void prepareUIComponents() {
    // 確保 inventory 和 equipment 在創建 UI 前已經初始化
    if (!_uiInitialized) {
      initInventory();
      initEquipment();
    }

    // 創建背包UI
    inventoryUI = InventoryUI(inventory: inventory, equipment: equipment);

    // 創建角色面板
    characterPanel = CharacterPanel();

    // 創建對話系統
    dialogueSystem = DialogueSystem();
  }

  /// 添加 UI 組件到遊戲組件樹（應在玩家完全添加到組件樹後調用）
  Future<void> addUIComponentsToGame() async {
    if (_uiInitialized) return;

    // 添加背包 UI
    await gameRef.game.cameraComponent.viewport.add(inventoryUI);

    // 添加角色面板
    await gameRef.game.cameraComponent.viewport.add(characterPanel);

    // 添加對話系統
    await gameRef.game.cameraComponent.viewport.add(dialogueSystem);

    _uiInitialized = true;
  }

  /// 舊的初始化方法（為向後兼容保留，但內部改為使用新的方式）
  void initUIComponents() {
    prepareUIComponents();
    // 不在這裡添加到組件樹，而是在遊戲適當時機調用 addUIComponentsToGame
  }

  /// 添加初始物品到背包
  void _addStartingItems() {
    // 添加藥水物品
    final healthPotion = PotionItem(
      id: 'health_potion_small',
      name: '小型治療藥水',
      description: '恢復25點生命值',
      healthRestored: 25,
      quantity: 3,
      rarity: ItemRarity.common,
    );

    final manaPotion = PotionItem(
      id: 'mana_potion_small',
      name: '小型魔法藥水',
      description: '恢復25點魔力值',
      manaRestored: 25,
      quantity: 3,
      rarity: ItemRarity.common,
    );

    // 確保添加所有三種武器到背包
    final pistolItem = WeaponItem.createPistolItem(ItemRarity.uncommon);
    final shotgunItem = WeaponItem.createShotgunItem(ItemRarity.common);
    // 添加機關槍，這樣所有武器都會在背包中
    final machineGunItem = WeaponItem.createMachineGunItem(ItemRarity.common);

    // 添加到背包
    inventory.addItem(healthPotion);
    inventory.addItem(manaPotion);
    inventory.addItem(pistolItem);
    inventory.addItem(shotgunItem);
    inventory.addItem(machineGunItem); // 添加機關槍到背包

    // 新增: 同步武器到戰鬥系統
    syncWeaponsWithCombatSystem();
  }

  // 新方法: 同步背包武器到戰鬥系統
  void syncWeaponsWithCombatSystem() {
    // 先清空現有戰鬥武器
    player.combat.clearWeapons();

    // 從背包獲取武器
    final weaponItems = inventory.items.whereType<WeaponItem>().toList();

    print("【調試】從背包中同步武器到戰鬥系統 - 找到 ${weaponItems.length} 把武器");

    // 為每個武器物品添加對應武器到戰鬥系統
    for (final weaponItem in weaponItems) {
      final weapon = weaponItem.weapon;
      player.combat.addWeapon(weapon);
      print("【調試】已添加武器 ${weapon.name} 到戰鬥系統");
    }
  }

  // 添加安全獲取控制器的方法
  InventoryUIController? getSafeController() {
    // 確保 inventoryUI 已初始化
    if (!_uiInitialized) {
      print("【警告】UI 組件尚未初始化，無法獲取控制器");
      return null;
    }

    try {
      return inventoryUI.controller;
    } catch (e) {
      print("【錯誤】獲取控制器失敗: $e");
      return null;
    }
  }

  /// 切換背包顯示狀態
  bool toggleInventory() {
    // 安全檢查：如果UI組件尚未初始化，則不執行操作並返回false
    if (!_uiInitialized) {
      print("【UI錯誤】嘗試切換背包顯示狀態，但UI組件尚未完全初始化");
      return false;
    }

    try {
      // 如果對話框開著，則先關閉
      if (dialogueSystem.isVisible) {
        dialogueSystem.closeDialogue();
      }

      // 使用安全方法獲取控制器
      InventoryUIController? controller = getSafeController();
      if (controller != null) {
        // 直接操作控制器狀態，而不是通過UI組件調用
        if (controller.isVisible) {
          controller.close();
        } else {
          controller.open();
        }
        return controller.isVisible;
      } else {
        print("【UI警告】無法安全獲取背包控制器，操作被取消");
        return false;
      }
    } catch (e) {
      print("【UI錯誤】切換背包顯示狀態時發生錯誤: $e");
      return false;
    }
  }

  /// 切換角色面板顯示狀態
  bool toggleCharacterPanel() {
    // 現在直接調用背包UI，因為角色狀態已整合到背包中
    return toggleInventory();
  }

  /// 使用背包中的物品
  bool useInventoryItem(int index) {
    return inventory.useItem(index);
  }

  /// 撿起物品
  bool pickupItem(Item item) {
    final result = inventory.addItem(item);
    if (result) {
      // 在此處可以添加撿起物品的視覺/音效反饋
    }
    return result;
  }

  /// 丟棄物品
  bool dropItem(String itemId, {int quantity = 1}) {
    final result = inventory.removeItem(itemId, quantity: quantity);
    if (result) {
      // 在此處可以添加丟棄物品的視覺/音效反饋
    }
    return result;
  }

  /// 裝備物品
  bool equipItem(int inventoryIndex) {
    if (inventoryIndex < 0 || inventoryIndex >= inventory.items.length) {
      return false;
    }

    final item = inventory.items[inventoryIndex];
    if (!item.isEquippable) return false;

    final equipType = item.equipType!;

    // 先卸下同類型的裝備
    final oldItem = equipment.unequip(equipType);

    // 裝備新物品
    bool equipped = equipment.equip(item);

    if (equipped) {
      // 如果成功裝備，從背包移除該物品
      inventory.removeItemAt(inventoryIndex);

      // 如果有舊裝備，加入背包
      if (oldItem != null) {
        inventory.addItem(oldItem);
      }

      // 通知更新玩家屬性
      updatePlayerStats();

      // 如果裝備的是武器，通知武器系統變更
      if (equipType == 'weapon') {
        // 通知熱鍵系統武器變更
        if (player.onWeaponsChanged != null) {
          player.onWeaponsChanged!();
        }

        // 更新熱鍵欄位
        if (gameRef.game.hotkeysHud != null) {
          gameRef.game.hotkeysHud.updateWeaponReferences();
        }

        print("【調試】裝備武器: ${item.name}，已通知熱鍵系統");
      }
    }

    return equipped;
  }

  /// 卸下裝備
  bool unequipItem(String slot) {
    final item = equipment.unequip(slot);
    if (item != null) {
      inventory.addItem(item);
      updatePlayerStats();

      // 如果卸下的是武器，通知武器系統變更
      if (slot == 'weapon') {
        // 通知熱鍵系統武器變更
        if (player.onWeaponsChanged != null) {
          player.onWeaponsChanged!();
        }

        // 更新熱鍵欄位
        if (gameRef.game.hotkeysHud != null) {
          gameRef.game.hotkeysHud.updateWeaponReferences();
        }

        print("【調試】卸下武器: ${item.name}，已通知熱鍵系統");
      }

      return true;
    }
    return false;
  }

  /// 取得所有裝備加成的總和
  Map<String, double> getTotalEquipmentStats() {
    return equipment.getTotalStats();
  }

  /// 更新玩家屬性的回調函數，將在子類中實現
  void updatePlayerStats() {
    // 這個方法會在主 Player 類中被覆蓋實現
  }

  /// 檢查UI是否開啟
  bool get isUIVisible {
    // 安全檢查：如果UI組件尚未初始化，則返回false
    if (!_uiInitialized) return false;

    try {
      final inventoryVisible = getSafeController()?.isVisible ?? false;
      final characterPanelVisible = characterPanel.isVisible;
      final dialogueVisible = dialogueSystem.isVisible;

      return inventoryVisible || characterPanelVisible || dialogueVisible;
    } catch (e) {
      // 如果任何UI組件尚未完全初始化，則返回false
      print("【UI錯誤】UI組件尚未完全初始化: $e");
      return false;
    }
  }
}
