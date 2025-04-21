import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../components/items/item.dart';
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

  HotkeyItem.weapon(this.item, this.weaponIndex, {this.name = '', Color? color}) : type = HotkeyItemType.weapon, color = color ?? Colors.blue;

  HotkeyItem.consumable(Item this.item) : type = HotkeyItemType.consumable, weaponIndex = null, name = item.name, color = item.rarityColor;

  HotkeyItem.empty() : type = HotkeyItemType.none, item = null, weaponIndex = null, name = '', color = Colors.grey;

  bool get isEmpty => type == HotkeyItemType.none;
}

/// 快捷鍵 HUD 組件，顯示在畫面上的快捷鍵槽位
class HotkeysHud extends PositionComponent with HasGameReference<NightAndRainGame> {
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

  HotkeysHud() : super(priority: 10) {
    // 設定在畫面底部
    size = Vector2((slotSize + slotSpacing) * hotkeyCount - slotSpacing, slotSize);
  }

  @override
  Future<void> onLoad() async {
    try {
      // 根據螢幕尺寸調整位置，放在畫面底部中央
      position = Vector2(game.size.x / 2 - size.x / 2, game.size.y - slotSize - 20);

      // 載入物品精靈圖表
      await _loadSpriteSheet();

      // 初始化武器熱鍵延遲到首次更新
      // 不再在onLoad中調用_initDefaultWeaponHotkeys()
    } catch (e) {
      print("【錯誤】初始化HotkeysHud失敗: $e");
    }

    await super.onLoad();
  }

  /// 載入物品精靈圖表
  Future<void> _loadSpriteSheet() async {
    try {
      final image = await Flame.images.load('item_pack.png');
      _spriteSheet = SpriteSheet(image: image, srcSize: Vector2(24, 24));
      print("物品精靈圖載入成功");
    } catch (e) {
      print("載入物品精靈圖失敗: $e");
    }
  }

  /// 初始化預設武器快捷鍵
  void _initDefaultWeaponHotkeys() {
    try {
      print("初始化預設武器快捷鍵，玩家武器數量: ${player.combat.weapons.length}");
      // 綁定前三個槽位為玩家的武器
      for (int i = 0; i < player.combat.weapons.length && i < 3; i++) {
        final weapon = player.combat.weapons[i];
        print("綁定默認武器: ${weapon.name} 到熱鍵槽 $i");
        setWeaponHotkey(i, weapon, i);
      }

      // 設置第一個熱鍵為選中狀態
      if (player.combat.weapons.isNotEmpty) {
        selectedSlot = 0;
      }
    } catch (e) {
      print("【錯誤】初始化預設武器快捷鍵時發生錯誤: $e");
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
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(10)), bgPaint);

    // 繪製邊框
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(10)), borderPaint);

    // 繪製每個快捷鍵槽位
    for (int i = 0; i < hotkeyCount; i++) {
      final x = i * (slotSize + slotSpacing);

      // 繪製槽位
      final slotRect = Rect.fromLTWH(x, 0, slotSize, slotSize);

      // 移除選中槽位高亮的繪製邏輯

      // 繪製槽位號碼
      _drawText(canvas, '${i + 1}', Vector2(x + slotSize - 8, 8), align: TextAlign.right, fontSize: 14, bold: true);

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
            weaponSprite.render(canvas, position: Vector2(x + (slotSize - iconSize) / 2, (slotSize - iconSize) / 2), size: Vector2.all(iconSize));

            break;
          case HotkeyItemType.consumable:
            final item = hotkey.item as Item;
            // 如果物品有精靈圖，直接使用
            if (item.sprite != null) {
              final iconSize = slotSize * 0.7;
              item.sprite!.render(canvas, position: Vector2(x + (slotSize - iconSize) / 2, (slotSize - iconSize) / 2), size: Vector2.all(iconSize));
            }

            // 如果是可堆疊物品且數量大於1，顯示數量
            if (item.isStackable && item.quantity > 1) {
              _drawText(canvas, item.quantity.toString(), Vector2(x + slotSize - 8, slotSize - 8), align: TextAlign.right, fontSize: 12, bold: true);
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
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
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

  /// 使用指定快捷鍵
  void useHotkey(int slot) {
    if (slot < 0 || slot >= hotkeyCount) return;

    // 檢查UI是否開啟，如果開啟則禁止使用快捷鍵
    if (player.inventory.isUIVisible) {
      return;
    }

    final hotkey = hotkeys[slot];
    switch (hotkey.type) {
      case HotkeyItemType.weapon:
        // 切換到對應武器
        if (hotkey.weaponIndex != null) {
          player.switchWeapon(hotkey.weaponIndex!);
          // 僅記錄內部狀態，不處理視覺效果
          selectedSlot = slot;
        }
        break;
      case HotkeyItemType.consumable:
        // 使用消耗品
        final item = hotkey.item as Item;
        final success = item.use(player);

        // 如果用完了，清除這個槽位
        if (success && item.quantity <= 0) {
          clearHotkey(slot);
        }
        break;
      case HotkeyItemType.none:
        // 空槽位，不執行任何操作
        break;
    }
  }

  /// 更新快捷鍵槽位的武器引用
  void updateWeaponReferences() {
    print("更新熱鍵武器引用，目前玩家武器數量: ${player.combat.weapons.length}");

    try {
      for (int i = 0; i < hotkeyCount; i++) {
        final hotkey = hotkeys[i];
        if (hotkey.type == HotkeyItemType.weapon && hotkey.weaponIndex != null) {
          final weaponIndex = hotkey.weaponIndex!;
          if (weaponIndex < player.combat.weapons.length) {
            // 更新武器引用
            final weapon = player.combat.weapons[weaponIndex];
            print("更新熱鍵槽 $i 的武器引用: ${weapon.name}");
            hotkeys[i] = HotkeyItem.weapon(weapon, weaponIndex, name: weapon.name);
          } else {
            // 武器不存在了，清除槽位
            print("清除熱鍵槽 $i，原武器索引 $weaponIndex 超出範圍");
            clearHotkey(i);
          }
        }
      }

      // 檢查當前選中槽位是否有效，否則重置
      if (selectedSlot != -1 && (selectedSlot >= hotkeyCount || hotkeys[selectedSlot].isEmpty)) {
        resetSelectedSlot();
      }
    } catch (e) {
      print("【錯誤】更新熱鍵武器引用時發生錯誤: $e");
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
    bool firstUpdate = true;
    if (firstUpdate) {
      firstUpdate = false;
      // 延遲初始化，確保player和weapons已準備好
      Future.delayed(Duration(milliseconds: 100), () {
        _initDefaultWeaponHotkeys();
      });
    }
  }
}
