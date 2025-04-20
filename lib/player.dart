import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/enums/item_rarity.dart';
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
import 'ui/Inventory_ui.dart';

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
  final double speed = 200.0;
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

  // =========== 武器系統 ===========
  double weaponAngle = 0.0;
  bool isShooting = false;
  List<Weapon> weapons = [];
  int currentWeaponIndex = 0;
  Weapon get currentWeapon => weapons[currentWeaponIndex];
  TextComponent? weaponInfoText;

  // =========== 背包系統 ===========
  late Inventory inventory;
  late InventoryUI inventoryUI;
  bool isInventoryVisible = false;

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
    await super.onLoad();
  }

  void _initInventory() {
    // 創建背包實例
    inventory = Inventory(player: this);

    // 創建背包UI
    inventoryUI = InventoryUI(inventory: inventory);

    // Instead of adding to game directly, add to the viewport
    game.cameraComponent.viewport.add(inventoryUI);

    // 添加一些初始物品到背包
    _addStartingItems();
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

    // 添加武器物品 - 這些武器只是示例，玩家已有三種基本武器
    final pistolItem = WeaponItem(
      id: 'weapon_pistol',
      name: '新手手槍',
      description: '基本的手槍，適合初學者使用',
      weapon: Pistol(),
      rarity: ItemRarity.common,
    );

    // 添加到背包
    inventory.addItem(healthPotion);
    inventory.addItem(manaPotion);
    inventory.addItem(pistolItem);
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
    // 添加三種武器
    weapons.addAll([Pistol(), Shotgun(), MachineGun()]);

    // 設置武器信息顯示
    weaponInfoText = VisibleTextComponent(
      text: '武器: ${currentWeapon.name}',
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
    final nearestNPC = game.gameWorld.interactWithNearestNPC(
      position,
      maxDistance: interactionRadius,
    );

    if (nearestNPC != null && interactingNPC == null) {
      canInteract = true;
    } else if (interactingNPC == null) {
      canInteract = false;
    }

    // 如果玩家走遠了，關閉對話
    if (interactingNPC != null) {
      final distance = position.distanceTo(interactingNPC!.position);
      if (distance > interactionRadius * 1.5) {
        hideDialogue();
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

    // 如果背包是開著的，禁用移動
    if (inventoryUI.isVisible) {
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

    // 武器切換
    if (keysPressed.contains(LogicalKeyboardKey.digit1)) {
      switchWeapon(0);
    } else if (keysPressed.contains(LogicalKeyboardKey.digit2)) {
      switchWeapon(1);
    } else if (keysPressed.contains(LogicalKeyboardKey.digit3)) {
      switchWeapon(2);
    }
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
        weaponInfoText!.text = '武器: ${currentWeapon.name}';
      }
    }
  }

  void shoot() {
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

  // =========== NPC互動 ===========

  void attemptInteraction() {
    if (interactingNPC != null) {
      hideDialogue();
      interactingNPC = null;
    } else {
      interactingNPC = game.gameWorld.interactWithNearestNPC(
        position,
        maxDistance: interactionRadius,
      );

      if (interactingNPC != null) {
        showDialogue(interactingNPC!.getRandomDialogue());
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
