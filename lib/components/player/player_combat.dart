import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../main.dart';
import '../weapons/weapon.dart';
import '../weapons/pistol.dart';
import '../weapons/shotgun.dart';
import '../weapons/machine_gun.dart';
import '../enums/item_rarity.dart';
import '../../ui/hotkeys_hud.dart';

/// 專門處理玩家戰鬥系統的類別
class PlayerCombat {
  // 武器系統
  double weaponAngle = 0.0;
  bool isShooting = false;
  List<Weapon> weapons = [];
  int currentWeaponIndex = 0;
  final int maxWeapons = 5; // 玩家最多可持有的武器數量

  // 獲取當前武器的便捷方法
  Weapon get currentWeapon => weapons[currentWeaponIndex];

  // 參考主玩家實例
  final player; // Player 類型，存儲對 Player 實例的引用

  // 參考遊戲主類
  final HasGameReference<NightAndRainGame> gameRef;

  // 生命值和魔法值系統
  int maxHealth;
  int currentHealth;
  int maxMana;
  int currentMana;
  double manaRegenCooldown = 0.0;
  final double manaRegenRate;
  final double healthRegenRate;

  // 戰鬥屬性
  double attack;
  double defense;
  double speed;
  int level;
  int experience;
  int experienceToNextLevel;

  // 狀態
  bool isDead = false;

  PlayerCombat({
    required this.gameRef,
    this.maxHealth = 100,
    this.maxMana = 100,
    this.attack = 10.0,
    this.defense = 5.0,
    this.speed = 10.0,
    this.level = 1,
    this.experience = 0,
    this.experienceToNextLevel = 100,
    this.manaRegenRate = 0.5,
    this.healthRegenRate = 1.0,
  }) : player = gameRef, // 在构造函数中将 gameRef 赋值给 player
       currentHealth = maxHealth,
       currentMana = maxMana;

  /// 初始化武器系統
  void initWeapons() {
    // 添加三種武器，並賦予稀有度
    weapons.addAll([Pistol(rarity: ItemRarity.common), Shotgun(rarity: ItemRarity.common), MachineGun(rarity: ItemRarity.common)]);

    // 通知武器變更
    _notifyWeaponsChanged();
  }

  /// 更新武器系統
  void update(double dt, Vector2 playerPosition, Vector2 velocity) {
    // 更新所有武器的冷卻時間
    for (final weapon in weapons) {
      weapon.update(dt);
    }

    // 處理射擊邏輯
    if (isShooting && !isDead) {
      final manaCost = getCurrentWeaponManaCost();
      if (currentMana >= manaCost) {
        if (currentWeapon.shoot(playerPosition, weaponAngle, gameRef.game)) {
          useMana(manaCost);
        }
      } else {
        isShooting = false;
        // 魔法不足警告由主Player類呼叫
      }
    }

    // 更新資源恢復
    updateResourceRegeneration(dt, velocity);
  }

  /// 更新資源恢復（生命值、魔法值）
  void updateResourceRegeneration(double dt, Vector2 velocity) {
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

  /// 更新武器角度
  void updateWeaponAngle(Vector2 playerPosition, Vector2 targetPosition) {
    final weaponDirection = targetPosition - playerPosition;
    weaponAngle = math.atan2(weaponDirection.y, weaponDirection.x);
  }

  /// 嘗試射擊
  bool shoot() {
    if (isDead) return false;

    if (currentMana >= getCurrentWeaponManaCost()) {
      // 同時設置持續射擊狀態，用於長按
      isShooting = true;
      return true;
    }
    return false;
  }

  /// 停止射擊
  void stopShooting() => isShooting = false;

  /// 切換武器
  bool switchWeapon(int index) {
    if (index < 0 || index >= weapons.length) return false;

    currentWeaponIndex = index;

    // 更新熱鍵系統中顯示的當前選中武器
    gameRef.game.hotkeysHud.selectedSlot = gameRef.game.hotkeysHud.hotkeys.indexWhere((hotkey) => hotkey.weaponIndex == index);

    // 通知武器變更
    _notifyWeaponsChanged();

    return true;
  }

  /// 添加武器到玩家的武器列表
  bool addWeapon(Weapon weapon) {
    if (weapons.length >= maxWeapons) return false;
    weapons.add(weapon);

    // 通知武器變更
    _notifyWeaponsChanged();

    return true;
  }

  /// 移除武器
  bool removeWeapon(int index) {
    if (index < 0 || index >= weapons.length) return false;

    // 如果移除的是當前武器，則切換到第一把武器
    if (index == currentWeaponIndex) {
      currentWeaponIndex = 0;
    }
    // 如果移除的武器在當前武器之前，需要調整當前武器索引
    else if (index < currentWeaponIndex) {
      currentWeaponIndex--;
    }

    weapons.removeAt(index);

    // 通知武器變更
    _notifyWeaponsChanged();

    return true;
  }

  /// 通知武器列表已變更
  void _notifyWeaponsChanged() {
    // 使用 player 而非 gameRef 來訪問 _onWeaponsChanged
    if (player._onWeaponsChanged != null) {
      player._onWeaponsChanged!();
    }
  }

  /// 獲取當前武器的魔法消耗
  int getCurrentWeaponManaCost() {
    return switch (currentWeapon) {
      Pistol() => 5,
      Shotgun() => 15,
      MachineGun() => 3,
      _ => 5,
    };
  }

  /// 受到傷害
  void takeDamage(int amount) {
    if (isDead) return;

    currentHealth = math.max(0, currentHealth - amount);

    // 檢查是否死亡
    if (currentHealth <= 0) {
      die();
    }
  }

  /// 回復生命值
  void heal(int amount) {
    if (isDead) return;
    currentHealth = math.min(maxHealth, currentHealth + amount);
  }

  /// 消耗魔法值
  bool useMana(int amount) {
    if (currentMana >= amount) {
      currentMana -= amount;
      return true;
    }
    return false;
  }

  /// 回復魔法值
  void restoreMana(int amount) {
    currentMana = math.min(maxMana, currentMana + amount);
  }

  /// 死亡
  void die() {
    if (!isDead) {
      isDead = true;
      isShooting = false;
      // 死亡相關邏輯由主Player類處理
    }
  }

  /// 復活
  void revive() {
    isDead = false;
    currentHealth = maxHealth;
    currentMana = maxMana;
  }

  /// 更新角色屬性
  void updateStats({double? newAttack, double? newDefense, double? newSpeed, int? newMaxHealth, int? newMaxMana}) {
    // 更新各項屬性
    if (newAttack != null) attack = newAttack;
    if (newDefense != null) defense = newDefense;
    if (newSpeed != null) speed = newSpeed;

    // 更新最大生命值和魔力值
    if (newMaxHealth != null) {
      final healthDiff = newMaxHealth - maxHealth;
      maxHealth = newMaxHealth;
      if (healthDiff > 0) {
        currentHealth += healthDiff; // 增加當前生命值
      }
    }

    if (newMaxMana != null) {
      final manaDiff = newMaxMana - maxMana;
      maxMana = newMaxMana;
      if (manaDiff > 0) {
        currentMana += manaDiff; // 增加當前魔力值
      }
    }
  }
}
