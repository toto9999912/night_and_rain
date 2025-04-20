import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/enums/item_rarity.dart';
import 'components/enums/item_type.dart';
import 'components/items/potion_item.dart';
import 'components/items/weapon_item.dart';
import 'components/weapons/machine_gun.dart';
import 'components/weapons/pistol.dart';
import 'components/weapons/shotgun.dart';
import 'main.dart';
import 'npc.dart';
import 'components/weapons/weapon.dart';
import 'components/items/inventory.dart';
import 'components/items/item.dart';
import 'components/items/equipment.dart';
import 'ui/Inventory_ui.dart';
import 'ui/dialogue_system.dart';
import 'ui/character_panel.dart';

/// 定義角色動畫狀態
enum PlayerState { idle, walking, dead }

/// 自訂可見性文字元件
class VisibleTextComponent extends TextComponent with HasVisibility {
  VisibleTextComponent({
    required String super.text,
    required TextPaint super.textRenderer,
    required Vector2 super.position,
    required Anchor super.anchor,
    super.priority,
  });
}

/// 玩家角色類
class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameReference<NightAndRainGame>, KeyboardHandler {
  // =========== 移動與物理參數 ===========
  final double moveSpeed = 200.0; // 移動速度 (原來的 speed)
  final double acceleration = 1200.0;
  final double deceleration = 2400.0;
  final double maxSpeed = 300.0;
  final Vector2 mapSize;

  Vector2 direction = Vector2.zero();
  Vector2 velocity = Vector2.zero();

  // =========== 角色狀態 ===========
  bool isDead = false;

  // 生命值和魔法值系統
  int maxHealth = 100;
  int currentHealth = 100;
  int maxMana = 100;
  int currentMana = 100;
  double manaRegenCooldown = 0.0;
  final double manaRegenRate = 0.5; // 每0.5秒恢復1點魔力
  final double healthRegenRate = 1.0; // 每秒恢復的生命值，休息時

  // 戰鬥屬性
  double attack = 10.0;
  double defense = 5.0;
  double speed = 10.0;
  int level = 1;
  int experience = 0;
  int experienceToNextLevel = 100;

  // =========== 武器系統 ===========
  double weaponAngle = 0.0;
  bool isShooting = false;
  List<Weapon> weapons = [];
  int currentWeaponIndex = 0;
  Weapon get currentWeapon => weapons[currentWeaponIndex];
  TextComponent? weaponInfoText;

  // =========== 背包系統 ===========
  late Inventory inventory;
  late Equipment equipment;
  late InventoryUI inventoryUI;
  late CharacterPanel characterPanel;
  late DialogueSystem dialogueSystem;

  // =========== NPC互動系統 ===========
  NPC? interactingNPC;
  bool canInteract = false;
  TextComponent? dialogueBox;
  final double interactionRadius = 60.0; // 與NPC互動的最大距離

  Player(this.mapSize)
    : super(
        size: Vector2.all(128),
        anchor: Anchor.center,
        position: Vector2(1000, 1000),
      );

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    _setupWeaponIndicator();
    _setupDialogueBox();
    _initWeapons();
    _initInventory();
    _initEquipment();
    _initUIComponents();
    await super.onLoad();
  }

  void _initInventory() {
    // 創建背包實例
    inventory = Inventory(player: this);

    // 添加一些初始物品到背包
    _addStartingItems();
  }

  void _initEquipment() {
    // 創建裝備系統
    equipment = Equipment();
  }

  void _initUIComponents() {
    // 創建背包UI
    inventoryUI = InventoryUI(inventory: inventory, equipment: equipment);
    game.cameraComponent.viewport.add(inventoryUI);

    // 創建角色面板
    characterPanel = CharacterPanel();
    game.cameraComponent.viewport.add(characterPanel);

    // 創建對話系統
    dialogueSystem = DialogueSystem();
    game.cameraComponent.viewport.add(dialogueSystem);
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

    // 添加裝備示例
    // final helmetItem = Item(
    //   id: 'helmet_leather',
    //   name: '皮革頭盔',
    //   description: '基本的皮革頭盔，提供少量防禦',
    //   type: ItemType.equipment,
    //   rarity: ItemRarity.uncommon,
    //   isEquippable: true,
    //   equipType: 'helmet',
    //   stats: {'defense': 3.0, 'maxHealth': 10.0},
    // );

    // 添加到背包
    inventory.addItem(healthPotion);
    inventory.addItem(manaPotion);
    inventory.addItem(pistolItem);
    inventory.addItem(shotgunItem);
  }

  /// 載入角色動畫
  Future<void> _loadAnimations() async {
    // 載入精靈圖
    final image = await Flame.images.load('player.png');
    final double stepTime = 0.2;
    final spriteSize = Vector2.all(32);

    // 靜止動畫 (第一橫排，3幀)
    final idleAnimation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: stepTime,
        textureSize: spriteSize,
        amountPerRow: 3,
        texturePosition: Vector2(0, 0),
        loop: true,
      ),
    );

    // 行走動畫 (第二橫排，3幀)
    final walkingAnimation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: stepTime,
        textureSize: spriteSize,
        amountPerRow: 3,
        texturePosition: Vector2(0, spriteSize.y),
        loop: true,
      ),
    );

    // 死亡動畫 (第三橫排，3幀)
    final deadAnimation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 3,
        stepTime: stepTime,
        textureSize: spriteSize,
        amountPerRow: 3,
        texturePosition: Vector2(0, spriteSize.y * 2),
        loop: false,
      ),
    );

    // 添加所有動畫到群組
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.walking: walkingAnimation,
      PlayerState.dead: deadAnimation,
    };

    // 預設為靜止狀態
    current = PlayerState.idle;
  }

  /// 設置武器方向指示器
  void _setupWeaponIndicator() {
    add(
      RectangleComponent(
        size: Vector2(20, 2),
        position: size / 2,
        anchor: Anchor.centerLeft,
        angle: 0,
        paint: Paint()..color = Colors.redAccent,
      ),
    );
  }

  /// 設置對話框
  void _setupDialogueBox() {
    // 先前簡單的對話框現在由 DialogueSystem 取代，
    // 但仍保留該方法和基本對話框以兼容舊程式碼
    dialogueBox = VisibleTextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.white,
          backgroundColor: Color(0x99000000),
        ),
      ),
      position: Vector2(0, -70),
      anchor: Anchor.bottomCenter,
    )..priority = 10;

    add(dialogueBox!);
    (dialogueBox as HasVisibility).isVisible = false;
  }

  /// 初始化武器系統
  void _initWeapons() {
    // 添加三種武器，並賦予稀有度
    weapons.addAll([
      Pistol(rarity: ItemRarity.common),
      Shotgun(rarity: ItemRarity.common),
      MachineGun(rarity: ItemRarity.common),
    ]);

    // 設置武器信息顯示
    weaponInfoText = VisibleTextComponent(
      text: '武器: ${currentWeapon.name} (${currentWeapon.rarity.name})',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.white,
          backgroundColor: Color(0x99000000),
        ),
      ),
      position: Vector2(0, -40),
      anchor: Anchor.bottomCenter,
    )..priority = 10;

    add(weaponInfoText!);
  }

  // =========== 更新方法 ===========

  @override
  void update(double dt) {
    super.update(dt);

    if (!isDead) {
      _updateMovementPhysics(dt);
      _handleShooting(dt);
      _checkNPCInteractions();
      _updateResourceRegeneration(dt);
    }

    // 更新所有武器的冷卻時間
    for (final weapon in weapons) {
      weapon.update(dt);
    }

    // 確保動畫狀態與移動狀態同步
    _updateAnimationState();
  }

  /// 更新移動物理
  void _updateMovementPhysics(double dt) {
    // 平滑移動邏輯
    if (direction.length > 0) {
      velocity += direction * acceleration * dt;
      if (velocity.length > maxSpeed) {
        velocity.normalize();
        velocity *= maxSpeed;
      }
    } else {
      final slowDownAmount = deceleration * dt;
      velocity.length <= slowDownAmount
          ? velocity = Vector2.zero()
          : velocity -= velocity.normalized() * slowDownAmount;
    }

    // 更新位置並限制在地圖範圍內
    position += velocity * dt;
    position.clamp(Vector2.zero() + size / 2, mapSize - size / 2);
  }

  /// 更新動畫狀態
  void _updateAnimationState() {
    if (isDead) {
      current = PlayerState.dead;
    } else if (direction.length > 0) {
      current = PlayerState.walking;
    } else {
      current = PlayerState.idle;
    }

    // 處理角色面向
    if (direction.x != 0) {
      scale.x = direction.x < 0 ? -1.0 : 1.0;
    }
  }

  /// 處理射擊邏輯
  void _handleShooting(double dt) {
    if (isShooting && !isDead) {
      final manaCost = getCurrentWeaponManaCost();
      if (currentMana >= manaCost) {
        if (currentWeapon.shoot(position, weaponAngle, game)) {
          useMana(manaCost);
        }
      } else {
        isShooting = false;
        showManaWarning();
      }
    }
  }

  /// 檢查NPC互動
  void _checkNPCInteractions() {
    // 定義不同的互動距離
    final greetingRadius = interactionRadius * 1.2; // 問候半徑比互動半徑大
    final actionRadius = interactionRadius * 0.7; // 交談半徑比互動半徑小

    // 更新所有NPC的互動提示狀態
    for (final npc in game.gameWorld.npcs) {
      final distance = position.distanceTo(npc.position);

      // 如果玩家在問候半徑內，顯示問候語
      if (distance <= greetingRadius) {
        npc.setGreetingVisible(true);

        // 如果玩家在交互半徑內，顯示交互提示
        if (distance <= interactionRadius) {
          npc.setInteractionHintVisible(true);

          // 如果玩家在行動半徑內，允許互動
          if (distance <= actionRadius && interactingNPC == null) {
            canInteract = true;
          }
        } else {
          npc.setInteractionHintVisible(false);
        }
      } else {
        // 如果玩家走遠，隱藏所有提示
        npc.setGreetingVisible(false);
        npc.setInteractionHintVisible(false);
      }
    }

    // 如果玩家走遠了，關閉對話
    if (interactingNPC != null) {
      final distance = position.distanceTo(interactingNPC!.position);
      if (distance > interactionRadius * 1.5) {
        hideDialogue();
        dialogueSystem.closeDialogue();
        interactingNPC = null;
      }
    }
  }

  /// 更新資源恢復（生命值、魔法值）
  void _updateResourceRegeneration(double dt) {
    // 自動回復魔法值
    manaRegenCooldown += dt;
    if (manaRegenCooldown >= manaRegenRate) {
      if (currentMana < maxMana) {
        currentMana = math.min(maxMana, currentMana + 1);
      }
      manaRegenCooldown = 0.0;
    }

    // 當玩家靜止時恢復少量生命值
    if (velocity.length < 0.1 && currentHealth < maxHealth) {
      final healAmount = (healthRegenRate * dt).toInt();
      if (healAmount > 0) {
        heal(healAmount);
      }
    }
  }

  // =========== 輸入處理 ===========

  void updateMovement(Set<LogicalKeyboardKey> keysPressed) {
    if (isDead) return;

    // 如果背包或角色面板是開著的，禁用移動
    if (inventoryUI.isVisible ||
        characterPanel.isVisible ||
        dialogueSystem.isVisible) {
      direction = Vector2.zero();
      return;
    }

    direction = Vector2.zero();

    // 移動控制
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y = 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x = -1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x = 1;
    }

    if (direction.length > 0) {
      direction.normalize();
    }

    // 互動控制
    if (keysPressed.contains(LogicalKeyboardKey.keyE)) {
      attemptInteraction();
    }

    // 背包控制
    if (keysPressed.contains(LogicalKeyboardKey.keyI)) {
      toggleInventory();
    }

    // 角色面板控制
    if (keysPressed.contains(LogicalKeyboardKey.keyC)) {
      toggleCharacterPanel();
    }

    // 注意：武器切換已經移至 HotkeysHud 處理，不再從這裡直接控制
  }

  void updateWeaponAngle(Vector2 targetPosition) {
    final weaponDirection = targetPosition - position;
    weaponAngle = math.atan2(weaponDirection.y, weaponDirection.x);

    // 更新武器指示器的角度
    final weaponIndicator =
        children.whereType<RectangleComponent>().firstOrNull;
    if (weaponIndicator != null) {
      weaponIndicator.angle = weaponAngle;
    }
  }

  // =========== 武器系統 ===========

  void switchWeapon(int index) {
    if (index >= 0 && index < weapons.length && currentWeaponIndex != index) {
      currentWeaponIndex = index;
      if (weaponInfoText != null) {
        weaponInfoText!.text =
            '武器: ${currentWeapon.name} (${currentWeapon.rarity.name})';
      }
    }
  }

  void shoot() {
    // 檢查 UI 是否開啟，如果開啟則禁止射擊
    if (inventoryUI.isVisible ||
        characterPanel.isVisible ||
        dialogueSystem.isVisible) {
      return;
    }

    if (!isDead && currentMana >= getCurrentWeaponManaCost()) {
      // 直接嘗試射擊
      if (currentWeapon.shoot(position, weaponAngle, game)) {
        useMana(getCurrentWeaponManaCost());
      }
      // 同時設置持續射擊狀態，用於長按
      isShooting = true;
    } else {
      showManaWarning();
    }
  }

  void stopShooting() => isShooting = false;

  int getCurrentWeaponManaCost() {
    return switch (currentWeapon) {
      Pistol() => 5,
      Shotgun() => 15,
      MachineGun() => 3,
      _ => 5,
    };
  }

  // =========== 背包系統 ===========

  /// 切換背包顯示狀態
  void toggleInventory() {
    // 如果對話框開著，則先關閉
    if (dialogueSystem.isVisible) {
      dialogueSystem.closeDialogue();
    }

    inventoryUI.toggle();
    // 當背包開啟時，停止移動和射擊
    if (inventoryUI.isVisible) {
      isShooting = false;
      velocity = Vector2.zero();
      direction = Vector2.zero();
    }
  }

  /// 使用背包中的物品
  bool useInventoryItem(int index) {
    return inventory.useItem(index);
  }

  /// 撿起物品（未來可以擴展為查找地面上的物品）
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

  /// 切換角色面板顯示狀態
  void toggleCharacterPanel() {
    // 現在直接調用背包UI，因為角色狀態已整合到背包中
    toggleInventory();
  }

  // =========== NPC互動 ===========

  void attemptInteraction() {
    if (interactingNPC != null) {
      hideDialogue();
      dialogueSystem.closeDialogue();
      interactingNPC = null;
    } else {
      interactingNPC = game.gameWorld.interactWithNearestNPC(
        position,
        maxDistance: interactionRadius,
      );

      if (interactingNPC != null) {
        // 使用新的對話系統
        final dialogueText = interactingNPC!.getRandomDialogue();

        // 創建對話數據
        final dialogue = DialogueData(
          id:
              'npc_${interactingNPC!.id}_${DateTime.now().millisecondsSinceEpoch}',
          speaker: interactingNPC!.name,
          text: dialogueText,
          options: [
            DialogueOption(
              text: '再見',
              onSelected: () {
                hideDialogue();
                interactingNPC = null;
              },
            ),
            DialogueOption(
              text: '詢問更多',
              onSelected: () {
                final moreText = interactingNPC!.getRandomDialogue();
                showDialogue(moreText); // 使用舊的對話系統顯示更多對話
              },
            ),
          ],
        );

        // 顯示對話
        dialogueSystem.startDialogue(dialogue);

        // 同時兼容舊系統
        showDialogue(dialogueText);
      }
    }
  }

  void showDialogue(String text) {
    if (dialogueBox != null) {
      dialogueBox!.text = text;
      (dialogueBox as HasVisibility).isVisible = true;
    }
  }

  void hideDialogue() {
    if (dialogueBox != null) {
      (dialogueBox as HasVisibility).isVisible = false;
    }
  }

  // =========== 裝備系統 ===========

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

      // 更新玩家屬性
      _updatePlayerStats();
    }

    return equipped;
  }

  /// 卸下裝備
  bool unequipItem(String slot) {
    final item = equipment.unequip(slot);
    if (item != null) {
      inventory.addItem(item);
      _updatePlayerStats();
      return true;
    }
    return false;
  }

  /// 更新玩家屬性（基於裝備加成）
  void _updatePlayerStats() {
    // 獲取裝備加成
    final stats = equipment.getTotalStats();

    // 更新玩家屬性
    attack = 10.0 + (stats['attack'] ?? 0);
    defense = 5.0 + (stats['defense'] ?? 0);
    speed = 10.0 + (stats['speed'] ?? 0);

    // 更新最大生命值和魔力值
    final newMaxHealth = 100 + (stats['maxHealth'] ?? 0).toInt();
    final healthDiff = newMaxHealth - maxHealth;
    maxHealth = newMaxHealth;
    if (healthDiff > 0) {
      currentHealth += healthDiff; // 增加當前生命值
    }

    final newMaxMana = 100 + (stats['maxMana'] ?? 0).toInt();
    final manaDiff = newMaxMana - maxMana;
    maxMana = newMaxMana;
    if (manaDiff > 0) {
      currentMana += manaDiff; // 增加當前魔力值
    }
  }

  // =========== 狀態系統 ===========

  void takeDamage(int amount) {
    if (isDead) return;

    currentHealth = math.max(0, currentHealth - amount);

    // 檢查是否死亡
    if (currentHealth <= 0) {
      die();
    }
  }

  void heal(int amount) {
    if (isDead) return;
    currentHealth = math.min(maxHealth, currentHealth + amount);
  }

  bool useMana(int amount) {
    if (currentMana >= amount) {
      currentMana -= amount;
      return true;
    }
    return false;
  }

  void restoreMana(int amount) {
    currentMana = math.min(maxMana, currentMana + amount);
  }

  void die() {
    if (!isDead) {
      isDead = true;
      isShooting = false;
      velocity = Vector2.zero();
      current = PlayerState.dead;
      // 這裡可以添加死亡相關的額外邏輯，如音效、粒子效果等
    }
  }

  void revive() {
    isDead = false;
    currentHealth = maxHealth;
    currentMana = maxMana;
    current = PlayerState.idle;
  }

  // =========== UI顯示 ===========

  void showManaWarning() {
    final warningText = VisibleTextComponent(
      text: '魔法不足!',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(0, -90),
      anchor: Anchor.bottomCenter,
    )..priority = 11;

    add(warningText);

    // 1秒後自動移除警告
    Future.delayed(const Duration(seconds: 1), () {
      warningText.removeFromParent();
    });
  }
}
