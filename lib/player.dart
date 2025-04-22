import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'components/items/equipment.dart';
import 'components/weapons/weapon.dart';
import 'main.dart';
import 'components/player/player_animation.dart';
import 'components/player/player_movement.dart';
import 'components/player/player_combat.dart';
import 'components/player/player_inventory.dart';
import 'components/player/player_interaction.dart';
import 'ui/dialogue_system.dart';

/// 玩家角色類 - 重構版本
/// 使用組合模式將功能拆分到不同的子系統中
class Player extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameReference<NightAndRainGame>, KeyboardHandler {
  // 子系統模組
  late final PlayerAnimation
  animationSystem; // 改名為 animationSystem 避免與父類別的 animation getter 衝突
  late final PlayerMovement movement;
  late final PlayerCombat combat;
  late final PlayerInventory inventory;
  late final PlayerInteraction interaction;

  // 地圖大小
  final Vector2 mapSize;

  // 武器變更時的回調函數
  Function? _onWeaponsChanged;

  // 設置武器變更回調的setter
  set onWeaponsChanged(Function? callback) {
    _onWeaponsChanged = callback;
  }

  // 添加公開的 getter 以便從外部類別訪問
  Function? get onWeaponsChanged => _onWeaponsChanged;

  Player(this.mapSize)
    : super(
        size: Vector2.all(128),
        anchor: Anchor.center,
        position: Vector2(1000, 1000),
      );

  @override
  Future<void> onLoad() async {
    // 1. 初始化各個子系統
    _initSubsystems();

    // 2. 載入所有資源和設定
    await _loadResources();

    // 3. 確保背包武器與戰鬥系統同步
    inventory.syncWeaponsWithCombatSystem();

    await super.onLoad();
  }

  /// 初始化所有子系統
  void _initSubsystems() {
    // 初始化動畫系統
    animationSystem = PlayerAnimation(this);

    // 初始化移動系統
    movement = PlayerMovement(component: this, mapSize: mapSize);

    // 初始化戰鬥系統（修正傳入 player 參數）
    combat = PlayerCombat(gameRef: this, player: this);

    // 初始化對話系統（臨時創建，後面會替換）
    final tempDialogueSystem = DialogueSystem();

    // 初始化互動系統
    interaction = PlayerInteraction(
      gameRef: this,
      component: this,
      dialogueSystem: tempDialogueSystem,
    );

    // 初始化背包系統 (必須在其他系統之後初始化，因為需要它們)
    inventory = PlayerInventory(gameRef: this, player: this);
  }

  /// 載入所有資源
  Future<void> _loadResources() async {
    // 載入動畫
    await animationSystem.loadAnimations();

    // 初始化互動系統的對話框
    interaction.setupDialogueBox();

    // 初始化武器系統
    // combat.initWeapons();

    // 初始化背包與裝備系統
    inventory.initInventory();
    inventory.initEquipment();
    inventory.initUIComponents();

    // 更新互動系統的對話系統引用
    interaction.dialogueSystem = inventory.dialogueSystem;

    // 設置動畫更新器
    _setupAnimationSpeedControl();
  }

  // 動畫速度控制
  void _setupAnimationSpeedControl() {
    addAll([
      TimerComponent(
        period: 0.05,
        repeat: true,
        onTick: () {
          if (!combat.isDead) {
            animationSystem.adjustWalkingAnimationSpeed(
              movement.velocity,
              movement.maxSpeed,
              game.currentTime(),
            );
          }
        },
      ),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!combat.isDead) {
      // 更新移動系統
      movement.update(dt);

      // 更新戰鬥系統
      combat.update(dt, position, movement.velocity);

      // 檢查NPC互動
      interaction.checkNPCInteractions(position);
    }

    // 更新動畫狀態
    animationSystem.updateAnimationState(
      movement.velocity,
      movement.maxSpeed,
      combat.isDead,
    );
  }

  // =========== 輸入處理 ===========

  void updateMovement(Set<LogicalKeyboardKey> keysPressed) {
    if (combat.isDead) return;

    // 如果UI開啟，禁用移動
    if (inventory.isUIVisible) {
      movement.stopMovement();
      return;
    }

    // 處理移動輸入
    movement.handleInput(keysPressed);

    // 互動控制
    if (keysPressed.contains(LogicalKeyboardKey.keyE)) {
      interaction.attemptInteraction(position);
    }

    // 背包控制
    if (keysPressed.contains(LogicalKeyboardKey.keyI)) {
      toggleInventory();
    }

    // 角色面板控制
    if (keysPressed.contains(LogicalKeyboardKey.keyC)) {
      toggleCharacterPanel();
    }
  }

  void updateWeaponAngle(Vector2 targetPosition) {
    combat.updateWeaponAngle(position, targetPosition);
  }

  void switchWeapon(int index) {
    if (combat.switchWeapon(index)) {
      // 當武器成功切換後，會觸發 combat 中的 _notifyWeaponsChanged
      // 該方法會調用 onWeaponsChanged 回調，從而通知熱鍵系統更新

      // 這裡我們不需要直接操作 HotkeysHud 和 CurrentWeaponHud
      // 因為它們會透過事件機制接收更新通知
    }
  }

  void shoot() {
    // 檢查 UI 是否開啟，如果開啟則禁止射擊
    if (inventory.isUIVisible) return;

    if (!combat.shoot()) {
      showManaWarning();
    }
  }

  void stopShooting() => combat.stopShooting();

  // 委派到子系統的方法
  void toggleInventory() {
    if (inventory.toggleInventory()) {
      // 當背包開啟時，停止移動和射擊
      combat.stopShooting();
      movement.stopMovement();
    }
  }

  void toggleCharacterPanel() => inventory.toggleCharacterPanel();

  bool equipItem(int inventoryIndex) => inventory.equipItem(inventoryIndex);

  bool unequipItem(String slot) => inventory.unequipItem(slot);

  // 狀態系統
  void takeDamage(int amount) => combat.takeDamage(amount);

  void heal(int amount) => combat.heal(amount);

  void restoreMana(int amount) => combat.restoreMana(amount);

  void die() {
    combat.die();
    movement.stopMovement();
    animationSystem.changeState(PlayerState.dead);
  }

  void revive() {
    combat.revive();
    animationSystem.changeState(PlayerState.idle);
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

  // 获取当前武器
  Weapon? get currentWeapon => combat.currentWeapon;

  // 公开一些重要属性作为代理
  bool get isDead => combat.isDead;
  int get currentHealth => combat.currentHealth;
  int get maxHealth => combat.maxHealth;
  int get currentMana => combat.currentMana;
  int get maxMana => combat.maxMana;
  double get attack => combat.attack;
  double get defense => combat.defense;
  double get speed => combat.speed;
  int get level => combat.level;
  int get experience => combat.experience;
  int get experienceToNextLevel => combat.experienceToNextLevel;
  Equipment get equipment => inventory.equipment;
  List<Weapon> get weapons => combat.weapons; // 添加對 weapons 的代理
}
