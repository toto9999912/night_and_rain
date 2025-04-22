import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:night_and_rain/player.dart';
import '../../main.dart';
import '../weapons/weapon.dart';
import '../weapons/pistol.dart';
import '../weapons/shotgun.dart';
import '../weapons/machine_gun.dart';
import '../enums/item_rarity.dart';

/// 專門處理玩家戰鬥系統的類別
class PlayerCombat {
  // 武器系統
  double weaponAngle = 0.0;
  bool isShooting = false;

  // 將武器列表改為從裝備系統獲取
  List<Weapon> get weapons {
    final currentWeapon = player.equipment.getCurrentWeapon();
    return currentWeapon != null ? [currentWeapon] : [];
  }

  // 這個屬性保留用於兼容性，但其實只會返回0，因為我們現在只有一個當前武器
  int currentWeaponIndex = 0;

  final int maxWeapons = 5; // 玩家最多可持有的武器數量 (雖然現在只會有一個)

  // 獲取當前武器的便捷方法，從裝備系統中獲取
  Weapon? get currentWeapon => player.equipment.getCurrentWeapon();

  // 參考主玩家實例
  final Player player;

  // 參考遊戲主類
  final NightAndRainGame game;

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
    required HasGameReference<NightAndRainGame> gameRef,
    required this.player,
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
  }) : game = gameRef.game,
       currentHealth = maxHealth,
       currentMana = maxMana;

  /// 初始化武器系統 - 為了保持兼容性保留此方法，但現在只需通知武器變更
  void initWeapons() {
    // 通知武器變更
    _notifyWeaponsChanged();
  }

  /// 更新武器系統
  void update(double dt, Vector2 playerPosition, Vector2 velocity) {
    // 更新當前武器的冷卻時間
    final weapon = currentWeapon;
    if (weapon != null) {
      weapon.update(dt);
    }

    // 處理射擊邏輯
    if (isShooting && !isDead) {
      final manaCost = getCurrentWeaponManaCost();
      if (currentMana >= manaCost) {
        if (currentWeapon?.shoot(playerPosition, weaponAngle, game) ?? false) {
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

  /// 切換武器 - 為了保持兼容性保留此方法，但現在沒有實際作用
  bool switchWeapon(int index) {
    // 由於現在只有一個武器，這個方法不再起作用
    // 所有武器切換邏輯現在應該通過裝備系統處理
    _notifyWeaponsChanged();

    // 更新熱鍵系統中的選中狀態
    game.hotkeysHud.updateWeaponReferences();

    return true;
  }

  /// 清空武器列表 - 為兼容性保留，但現在它只是通知變更
  void clearWeapons() {
    _notifyWeaponsChanged();
  }

  /// 添加武器 - 為兼容性保留，但現在它只是通知變更
  bool addWeapon(Weapon weapon) {
    _notifyWeaponsChanged();
    return true;
  }

  /// 移除武器 - 為兼容性保留，但現在它只是通知變更
  bool removeWeapon(int index) {
    _notifyWeaponsChanged();
    return true;
  }

  /// 通知武器列表已變更
  void _notifyWeaponsChanged() {
    // 透過 player 參數訪問 onWeaponsChanged
    final callback = player.onWeaponsChanged;
    if (callback != null) {
      callback();
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
  void updateStats({
    double? newAttack,
    double? newDefense,
    double? newSpeed,
    int? newMaxHealth,
    int? newMaxMana,
  }) {
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
