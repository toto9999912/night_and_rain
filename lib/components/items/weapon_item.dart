import '../../player.dart';
import '../enums/item_rarity.dart';
import '../enums/item_type.dart';
import '../weapons/machine_gun.dart';
import '../weapons/pistol.dart';
import '../weapons/shotgun.dart';
import '../weapons/weapon.dart';
import 'item.dart';

/// 武器物品類
class WeaponItem extends Item {
  final Weapon weapon; // 關聯的武器實例

  WeaponItem({
    required super.id,
    required super.name,
    required super.description,
    required this.weapon,
    super.rarity,
    super.iconPath,
    super.spriteX = 0, // 預設使用精靈圖第一個位置
    super.spriteY = 0,
  }) : super(
         type: ItemType.weapon,
         maxStackSize: 1,
         isEquippable: true, // 添加這行，標記為可裝備
         equipType: 'weapon', // 添加這行，設定裝備類型
       );

  @override
  bool use(Player player) {
    // 在玩家的武器列表中查找此武器
    final existingWeaponIndex = player.weapons.indexWhere(
      (w) => w.runtimeType == weapon.runtimeType,
    );

    if (existingWeaponIndex >= 0) {
      // 如果玩家已有此武器，則切換到該武器
      player.switchWeapon(existingWeaponIndex);
      return true;
    } else {
      // 如果玩家沒有此武器，則添加到武器列表並切換
      player.weapons.add(weapon);
      player.switchWeapon(player.weapons.length - 1);
      quantity--; // 減少物品數量
      return true;
    }
  }

  @override
  Item copyWith({int? quantity}) {
    return WeaponItem(
      id: id,
      name: name,
      description: description,
      weapon: weapon,
      rarity: rarity,
      iconPath: iconPath,
    );
  }

  // 創建特定武器的工廠方法
  static WeaponItem createPistolItem(ItemRarity rarity) {
    final pistol = Pistol(rarity: rarity);
    return WeaponItem(
      id: 'weapon_pistol_${rarity.name}',
      name: '${rarity.name.toUpperCase()} ${pistol.name}',
      description: pistol.getDescription(),
      weapon: pistol,
      rarity: rarity,
      iconPath: 'assets/images/weapons/pistol.png',
      spriteX: 0, // 使用精靈圖的第一個位置
      spriteY: 0,
    );
  }

  static WeaponItem createShotgunItem(ItemRarity rarity) {
    final shotgun = Shotgun(rarity: rarity);
    return WeaponItem(
      id: 'weapon_shotgun_${rarity.name}',
      name: '${rarity.name.toUpperCase()} ${shotgun.name}',
      description: shotgun.getDescription(),
      weapon: shotgun,
      rarity: rarity,
      iconPath: 'assets/images/weapons/shotgun.png',
      spriteX: 1, // 使用精靈圖的第二個位置
      spriteY: 0,
    );
  }

  static WeaponItem createMachineGunItem(ItemRarity rarity) {
    final machineGun = MachineGun(rarity: rarity);
    return WeaponItem(
      id: 'weapon_machinegun_${rarity.name}',
      name: '${rarity.name.toUpperCase()} ${machineGun.name}',
      description: machineGun.getDescription(),
      weapon: machineGun,
      rarity: rarity,
      iconPath: 'assets/images/weapons/machinegun.png',
      spriteX: 2, // 使用精靈圖的第三個位置
      spriteY: 0,
    );
  }
}
