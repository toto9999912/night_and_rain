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

  /// 初始化UI組件
  void initUIComponents() {
    // 創建背包UI
    inventoryUI = InventoryUI(inventory: inventory, equipment: equipment);
    gameRef.game.cameraComponent.viewport.add(inventoryUI);

    // 創建角色面板
    characterPanel = CharacterPanel();
    gameRef.game.cameraComponent.viewport.add(characterPanel);

    // 創建對話系統
    dialogueSystem = DialogueSystem();
    gameRef.game.cameraComponent.viewport.add(dialogueSystem);
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

    // 使用工廠方法創建武器物品
    final pistolItem = WeaponItem.createPistolItem(ItemRarity.uncommon);
    final shotgunItem = WeaponItem.createShotgunItem(ItemRarity.common);

    // 添加到背包
    inventory.addItem(healthPotion);
    inventory.addItem(manaPotion);
    inventory.addItem(pistolItem);
    inventory.addItem(shotgunItem);
  }

  /// 切換背包顯示狀態
  bool toggleInventory() {
    // 如果對話框開著，則先關閉
    if (dialogueSystem.isVisible) {
      dialogueSystem.closeDialogue();
    }

    inventoryUI.toggle();
    return inventoryUI.controller.isVisible;
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

    // 先卸下同類型的裝備
    final oldItem = equipment.unequip(item.equipType!);

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
    }

    return equipped;
  }

  /// 卸下裝備
  bool unequipItem(String slot) {
    final item = equipment.unequip(slot);
    if (item != null) {
      inventory.addItem(item);
      updatePlayerStats();
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
  bool get isUIVisible => inventoryUI.controller.isVisible || characterPanel.isVisible || dialogueSystem.isVisible;
}
