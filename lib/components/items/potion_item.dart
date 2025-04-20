import '../../player.dart';
import '../enums/item_type.dart';
import 'item.dart';

/// 藥水物品類
class PotionItem extends Item {
  final int healthRestored; // 恢復生命值
  final int manaRestored; // 恢復魔法值
  final bool isBuff; // 是否為增益效果
  final Duration? buffDuration; // 增益效果持續時間

  PotionItem({
    required super.id,
    required super.name,
    required super.description,
    this.healthRestored = 0,
    this.manaRestored = 0,
    this.isBuff = false,
    this.buffDuration,
    super.maxStackSize = 5,
    super.quantity,
    super.rarity,
    super.iconPath,
  }) : super(type: ItemType.potion);

  @override
  bool use(Player player) {
    // 檢查是否需要使用該藥水
    bool shouldUse = false;

    // 如果是治療藥水但玩家已滿血，或是魔法藥水但玩家已滿魔力，則無需使用
    if ((healthRestored > 0 && player.currentHealth < player.maxHealth) ||
        (manaRestored > 0 && player.currentMana < player.maxMana) ||
        isBuff) {
      shouldUse = true;
    }

    if (shouldUse) {
      // 恢復生命值
      if (healthRestored > 0) {
        player.heal(healthRestored);
      }

      // 恢復魔法值
      if (manaRestored > 0) {
        player.restoreMana(manaRestored);
      }

      // 處理增益效果
      if (isBuff && buffDuration != null) {
        // 應用增益效果的代碼
        // player.applyBuff(name, buffDuration!);
      }

      // 減少數量，如果數量為0，物品會被從背包中移除
      quantity--;
      return true;
    }

    return false;
  }

  @override
  Item copyWith({int? quantity}) {
    return PotionItem(
      id: id,
      name: name,
      description: description,
      healthRestored: healthRestored,
      manaRestored: manaRestored,
      isBuff: isBuff,
      buffDuration: buffDuration,
      maxStackSize: maxStackSize,
      quantity: quantity ?? this.quantity,
      rarity: rarity,
      iconPath: iconPath,
    );
  }
}
