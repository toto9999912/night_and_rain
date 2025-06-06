import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../components/items/item.dart';
import '../components/items/weapon_item.dart';
import '../components/weapons/weapon.dart';
import '../components/weapons/pistol.dart';
import '../components/weapons/shotgun.dart';
import '../components/weapons/machine_gun.dart';
import '../main.dart';
import '../player.dart';

/// 可快捷使用的物品類型
enum HotkeyItemType { weapon, consumable, none }

/// 快捷鍵綁定的物品
class HotkeyItem {
  final HotkeyItemType type;
  final dynamic item; // 可能是 Weapon 或 Item
  final int? weaponIndex; // 如果是武器，儲存武器在玩家武器列表中的索引
  final String name;
  final Color color;

  HotkeyItem.weapon(this.item, this.weaponIndex, {this.name = '', Color? color})
    : type = HotkeyItemType.weapon,
      color = color ?? Colors.blue;

  HotkeyItem.consumable(Item this.item)
    : type = HotkeyItemType.consumable,
      weaponIndex = null,
      name = item.name,
      color = item.rarityColor;

  HotkeyItem.empty()
    : type = HotkeyItemType.none,
      item = null,
      weaponIndex = null,
      name = '',
      color = Colors.grey;

  bool get isEmpty => type == HotkeyItemType.none;
}

/// 快捷鍵 HUD 組件，顯示在畫面上的快捷鍵槽位
class HotkeysHud extends PositionComponent
    with HasGameReference<NightAndRainGame> {
  static const double slotSize = 44.0;
  static const double slotSpacing = 6.0;
  static const int hotkeyCount = 4;

  // 儲存快捷鍵綁定的物品或技能
  final List<HotkeyItem> hotkeys = List.filled(hotkeyCount, HotkeyItem.empty());

  // 玩家實例引用
  Player get player => game.player;

  // 選中的槽位 (從 0 開始，-1 表示沒有選中)
  int selectedSlot = -1;

  // 武器和物品的精靈圖
  SpriteSheet? _spriteSheet;

  // 標記是否為第一次更新
  bool _firstUpdate = true;

  HotkeysHud() : super(priority: 10) {
    // 設定在畫面底部
    size = Vector2(
      (slotSize + slotSpacing) * hotkeyCount - slotSpacing,
      slotSize,
    );
  }

  @override
  Future<void> onLoad() async {
    try {
      // 根據螢幕尺寸調整位置，放在畫面底部中央
      position = Vector2(
        game.size.x / 2 - size.x / 2,
        game.size.y - slotSize - 20,
      );

      // 載入物品精靈圖表
      await _loadSpriteSheet();

      // 初始化武器熱鍵延遲到首次更新
      // 不再在onLoad中調用_initDefaultWeaponHotkeys()
    } catch (e) {
      debugPrint("【錯誤】初始化HotkeysHud失敗: $e");
    }

    await super.onLoad();
  }

  /// 設置武器物品快捷鍵 (直接使用 WeaponItem 而不是 Weapon)
  void setWeaponItemHotkey(int slot, WeaponItem weaponItem) {
    if (slot >= 0 && slot < hotkeyCount) {
      // 從 WeaponItem 獲取 Weapon 實例
      final weapon = weaponItem.weapon;

      // 創建一個特殊的 HotkeyItem，weaponIndex 設為 -1 表示直接來自背包
      hotkeys[slot] = HotkeyItem.weapon(
        weapon,
        -1, // 使用 -1 表示這是直接從背包綁定的武器
        name: weaponItem.name,
      );

      debugPrint("【調試】成功綁定武器物品: ${weaponItem.name} 到熱鍵槽 $slot");

      // 如果沒有選中的槽位，將這個設為選中
      if (selectedSlot == -1) {
        selectedSlot = slot;
      }
    }
  }

  /// 載入物品精靈圖表
  Future<void> _loadSpriteSheet() async {
    try {
      final image = await Flame.images.load('item_pack.png');
      _spriteSheet = SpriteSheet(image: image, srcSize: Vector2(24, 24));
      debugPrint("物品精靈圖載入成功");
    } catch (e) {
      debugPrint("載入物品精靈圖失敗: $e");
    }
  }

  /// 初始化預設武器快捷鍵
  void _initDefaultWeaponHotkeys() {
    try {
      debugPrint("初始化預設武器快捷鍵，玩家武器數量: ${player.combat.weapons.length}");
      // 綁定前三個槽位為玩家的武器
      if (player.combat.weapons.isEmpty) return;
      for (int i = 0; i < player.combat.weapons.length && i < 3; i++) {
        final weapon = player.combat.weapons[i];
        debugPrint("綁定默認武器: ${weapon.name} 到熱鍵槽 $i");
        setWeaponHotkey(i, weapon, i);
      }

      // 設置第一個熱鍵為選中狀態
      if (player.combat.weapons.isNotEmpty) {
        selectedSlot = 0;
      }
    } catch (e) {
      debugPrint("【錯誤】初始化預設武器快捷鍵時發生錯誤: $e");
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bgPaint = Paint()..color = const Color(0xDD333333);
    final borderPaint =
        Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
    // 移除選中槽位的高亮繪製邏輯，不再使用 selectedPaint 和 selectedBorderPaint

    // 繪製背景
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      bgPaint,
    );

    // 繪製邊框
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      borderPaint,
    );

    // 繪製每個快捷鍵槽位
    for (int i = 0; i < hotkeyCount; i++) {
      final x = i * (slotSize + slotSpacing);

      // 繪製槽位
      final slotRect = Rect.fromLTWH(x, 0, slotSize, slotSize);

      // 移除選中槽位高亮的繪製邏輯

      // 繪製槽位號碼
      _drawText(
        canvas,
        '${i + 1}',
        Vector2(x + slotSize - 8, 8),
        align: TextAlign.right,
        fontSize: 14,
        bold: true,
      );

      // 如果有綁定物品，繪製相應信息
      final hotkey = hotkeys[i];
      if (!hotkey.isEmpty && _spriteSheet != null) {
        // 繪製物品圖示
        switch (hotkey.type) {
          case HotkeyItemType.weapon:
            final weapon = hotkey.item as Weapon;
            // 根據武器類型獲取對應圖示
            int spriteX = 0;
            int spriteY = 0;

            if (weapon is Pistol) {
              spriteX = 0;
              spriteY = 0;
            } else if (weapon is Shotgun) {
              spriteX = 1;
              spriteY = 0;
            } else if (weapon is MachineGun) {
              spriteX = 2;
              spriteY = 0;
            }

            // 繪製武器圖示
            final weaponSprite = _spriteSheet!.getSprite(spriteX, spriteY);
            final iconSize = slotSize * 0.7;
            weaponSprite.render(
              canvas,
              position: Vector2(
                x + (slotSize - iconSize) / 2,
                (slotSize - iconSize) / 2,
              ),
              size: Vector2.all(iconSize),
            );

            break;
          case HotkeyItemType.consumable:
            final item = hotkey.item as Item;
            // 如果物品有精靈圖，直接使用
            if (item.sprite != null) {
              final iconSize = slotSize * 0.7;
              item.sprite!.render(
                canvas,
                position: Vector2(
                  x + (slotSize - iconSize) / 2,
                  (slotSize - iconSize) / 2,
                ),
                size: Vector2.all(iconSize),
              );
            }

            // 如果是可堆疊物品且數量大於1，顯示數量
            if (item.isStackable && item.quantity > 1) {
              _drawText(
                canvas,
                item.quantity.toString(),
                Vector2(x + slotSize - 8, slotSize - 8),
                align: TextAlign.right,
                fontSize: 12,
                bold: true,
              );
            }
            break;
          case HotkeyItemType.none:
            // 空槽位不顯示圖示
            break;
        }
      }
    }
  }

  /// 文字繪製輔助方法
  void _drawText(
    Canvas canvas,
    String text,
    Vector2 position, {
    TextAlign align = TextAlign.center,
    double fontSize = 14,
    bool bold = false,
    Color color = Colors.white,
    double? maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    );

    if (maxWidth != null) {
      textPainter.layout(maxWidth: maxWidth);
    } else {
      textPainter.layout();
    }

    double x = position.x;
    if (align == TextAlign.center) {
      x -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      x -= textPainter.width;
    }

    textPainter.paint(canvas, Offset(x, position.y - textPainter.height / 2));
  }

  /// 設置武器快捷鍵
  void setWeaponHotkey(int slot, Weapon weapon, int weaponIndex) {
    if (slot >= 0 && slot < hotkeyCount) {
      hotkeys[slot] = HotkeyItem.weapon(weapon, weaponIndex, name: weapon.name);
    }
  }

  /// 設置消耗品快捷鍵
  void setConsumableHotkey(int slot, Item item) {
    if (slot >= 0 && slot < hotkeyCount) {
      hotkeys[slot] = HotkeyItem.consumable(item);
    }
  }

  /// 清除快捷鍵綁定
  void clearHotkey(int slot) {
    if (slot >= 0 && slot < hotkeyCount) {
      hotkeys[slot] = HotkeyItem.empty();
    }
  }

  void useHotkey(int slot) {
    if (slot < 0 || slot >= hotkeyCount) return;

    // 檢查UI是否開啟，如果開啟則禁止使用快捷鍵
    if (player.inventory.isUIVisible) {
      return;
    }

    final hotkey = hotkeys[slot];
    switch (hotkey.type) {
      case HotkeyItemType.weapon:
        // 先檢查已裝備的武器
        final equippedWeaponItem =
            player.inventory.equipment.slots['weapon'] as WeaponItem?;
        final weapon = hotkey.item as Weapon;

        // 如果該武器已裝備，不需要做任何事
        if (equippedWeaponItem != null &&
            equippedWeaponItem.weapon.runtimeType == weapon.runtimeType) {
          selectedSlot = slot;
          return;
        }

        // 在背包中尋找對應的 WeaponItem - 使用更安全的方式
        final matchingWeaponItems =
            player.inventory.inventory.items
                .whereType<WeaponItem>()
                .where((item) => item.weapon.runtimeType == weapon.runtimeType)
                .toList();

        if (matchingWeaponItems.isEmpty) {
          debugPrint("【警告】背包中找不到對應武器: ${weapon.runtimeType}");
          return;
        }

        final matchingWeaponItem = matchingWeaponItems.first;
        debugPrint(
          "【調試】武器屬性: isEquippable=${matchingWeaponItem.isEquippable}, equipType=${matchingWeaponItem.equipType}",
        );
        // 找到武器在背包中的索引
        final itemIndex = player.inventory.inventory.items.indexOf(
          matchingWeaponItem,
        );
        if (itemIndex >= 0) {
          // 裝備該武器
          final success = player.inventory.equipItem(itemIndex);
          debugPrint("【調試】通過熱鍵裝備武器: ${matchingWeaponItem.name}, 成功: $success");
        } else {
          debugPrint("【警告】無法找到武器在背包中的索引");
        }

        // 記錄選中的槽位
        selectedSlot = slot;
        break;

      case HotkeyItemType.consumable:
        // 使用消耗品
        final item = hotkey.item as Item;
        final success = item.use(player);

        // 如果用完了，清除這個槽位
        if (success && item.quantity <= 0) {
          clearHotkey(slot);

          // 同步從背包中移除數量為0的物品
          final itemIndex = player.inventory.inventory.items.indexOf(item);
          if (itemIndex >= 0) {
            player.inventory.inventory.removeItemAt(itemIndex);
          }
        }
        break;
      case HotkeyItemType.none:
        // 空槽位，不執行任何操作
        break;
    }
  }

  void updateWeaponReferences() {
    debugPrint("更新熱鍵武器引用，目前玩家武器數量: ${player.combat.weapons.length}");

    try {
      // 獲取背包中所有武器物品的列表
      final inventoryWeaponItems =
          player.inventory.inventory.items.whereType<WeaponItem>().toList();

      // 獲取當前裝備的武器物品
      final equippedWeaponItem =
          player.inventory.equipment.slots['weapon'] as WeaponItem?;

      // 合併背包和裝備欄中的武器類型列表
      final List<Type> availableWeaponTypes = [
        ...inventoryWeaponItems.map((item) => item.weapon.runtimeType),
        if (equippedWeaponItem != null) equippedWeaponItem.weapon.runtimeType,
      ];

      debugPrint("可用武器類型: $availableWeaponTypes");

      for (int i = 0; i < hotkeyCount; i++) {
        final hotkey = hotkeys[i];
        if (hotkey.type == HotkeyItemType.weapon) {
          final weapon = hotkey.item as Weapon;

          // 檢查該武器類型是否在背包或裝備欄中
          bool weaponAvailable = availableWeaponTypes.contains(
            weapon.runtimeType,
          );

          if (weaponAvailable) {
            debugPrint("熱鍵槽 $i 的武器類型 ${weapon.runtimeType} 可用");
          } else {
            debugPrint("清除熱鍵槽 $i，武器類型 ${weapon.runtimeType} 不可用");
            clearHotkey(i);
          }
        } else if (hotkey.type == HotkeyItemType.consumable) {
          // 保持原有消耗品檢查邏輯
        }
      }

      // 檢查當前選中槽位是否有效
      if (selectedSlot != -1 &&
          (selectedSlot >= hotkeyCount || hotkeys[selectedSlot].isEmpty)) {
        resetSelectedSlot();
      }
    } catch (e) {
      debugPrint("【錯誤】更新熱鍵武器引用時發生錯誤: $e");
    }
  }

  /// 重置選中槽位到第一個有效武器
  void resetSelectedSlot() {
    selectedSlot = -1;
    for (int i = 0; i < hotkeyCount; i++) {
      if (hotkeys[i].type == HotkeyItemType.weapon) {
        selectedSlot = i;
        break;
      }
    }
  }

  /// 選擇下一個槽位
  void selectNextSlot() {
    selectedSlot = (selectedSlot + 1) % hotkeyCount;
  }

  /// 選擇上一個槽位
  void selectPrevSlot() {
    selectedSlot = (selectedSlot - 1 + hotkeyCount) % hotkeyCount;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 初次更新時初始化熱鍵
    if (_firstUpdate) {
      _firstUpdate = false;
      // 延遲初始化，確保player和weapons已準備好
      Future.delayed(Duration(milliseconds: 100), () {
        _initDefaultWeaponHotkeys();
      });
    }
  }
}
