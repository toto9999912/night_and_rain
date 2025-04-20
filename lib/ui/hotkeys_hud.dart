import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../components/items/item.dart';
import '../components/weapons/weapon.dart';
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

  HotkeysHud() : super(priority: 10) {
    // 設定在畫面底部
    size = Vector2(
      (slotSize + slotSpacing) * hotkeyCount - slotSpacing,
      slotSize,
    );
  }

  @override
  Future<void> onLoad() async {
    // 根據螢幕尺寸調整位置，放在畫面底部中央
    position = Vector2(
      game.size.x / 2 - size.x / 2,
      game.size.y - slotSize - 20,
    );

    // 初始化快捷鍵槽位，預設綁定武器
    _initDefaultWeaponHotkeys();

    await super.onLoad();
  }

  /// 初始化預設武器快捷鍵
  void _initDefaultWeaponHotkeys() {
    // 綁定前三個槽位為玩家的武器
    for (int i = 0; i < player.weapons.length && i < 3; i++) {
      final weapon = player.weapons[i];
      setWeaponHotkey(i, weapon, i);
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
    final selectedPaint =
        Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

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

      // 如果這是當前選中的槽位，用特殊顏色標記
      if (i == selectedSlot) {
        canvas.drawRect(slotRect, selectedPaint);
      }

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
      if (!hotkey.isEmpty) {
        // 繪製彩色指示器，表示物品類型
        final indicatorPaint = Paint()..color = hotkey.color;
        canvas.drawRect(Rect.fromLTWH(x + 4, 4, 5, 5), indicatorPaint);

        // 繪製物品名稱或表示
        String itemText = '';
        Color textColor = Colors.white;

        switch (hotkey.type) {
          case HotkeyItemType.weapon:
            final weapon = hotkey.item as Weapon;
            itemText = weapon.name;
            // 如果這是當前選中的武器，使用不同顏色
            if (hotkey.weaponIndex == player.currentWeaponIndex) {
              textColor = Colors.yellow;
            }
            break;
          case HotkeyItemType.consumable:
            final item = hotkey.item as Item;
            itemText = item.name;
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
            itemText = '空';
            textColor = Colors.grey;
            break;
        }

        // 在槽位中央繪製物品名稱
        _drawText(
          canvas,
          itemText,
          Vector2(x + slotSize / 2, slotSize / 2),
          align: TextAlign.center,
          fontSize: 10,
          color: textColor,
          maxWidth: slotSize - 4,
        );
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

  /// 使用指定快捷鍵
  void useHotkey(int slot) {
    if (slot < 0 || slot >= hotkeyCount) return;

    // 檢查UI是否開啟，如果開啟則禁止使用快捷鍵
    if (player.inventoryUI.isVisible ||
        player.characterPanel.isVisible ||
        player.dialogueSystem.isVisible) {
      return;
    }

    final hotkey = hotkeys[slot];
    switch (hotkey.type) {
      case HotkeyItemType.weapon:
        // 切換到對應武器
        if (hotkey.weaponIndex != null) {
          player.switchWeapon(hotkey.weaponIndex!);
          // 更新選中的槽位
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
    for (int i = 0; i < hotkeyCount; i++) {
      final hotkey = hotkeys[i];
      if (hotkey.type == HotkeyItemType.weapon && hotkey.weaponIndex != null) {
        final weaponIndex = hotkey.weaponIndex!;
        if (weaponIndex < player.weapons.length) {
          // 更新武器引用
          final weapon = player.weapons[weaponIndex];
          hotkeys[i] = HotkeyItem.weapon(
            weapon,
            weaponIndex,
            name: weapon.name,
          );
        } else {
          // 武器不存在了，清除槽位
          clearHotkey(i);
        }
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
}
