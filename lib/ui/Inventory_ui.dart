import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';

import '../components/items/inventory.dart';
import '../components/items/equipment.dart'; // 新增裝備系統引用
import '../player.dart'; // 添加 Player 引用

/// 背包UI組件
class InventoryUI extends PositionComponent
    with TapCallbacks, KeyboardHandler, HasGameReference<NightAndRainGame> {
  final Inventory inventory;
  final Equipment equipment; // 新增裝備系統
  final double padding = 10.0;
  final double itemSize = 60.0;
  final double spacing = 5.0;
  int itemsPerRow = 5;

  // UI 狀態
  bool isVisible = false;
  int? hoveredItemIndex;
  int? selectedItemIndex;
  String? hoveredEquipSlot;
  String? selectedEquipSlot;

  // 角色面板相關設置
  final double lineHeight = 25.0;
  final Color titleColor = Colors.yellow;
  final Color valueColor = Colors.cyan;

  InventoryUI({required this.inventory, required this.equipment})
    : super(priority: 100);

  @override
  Future<void> onLoad() async {
    // 加載精靈圖
    final spriteSheet = SpriteSheet(
      image: await Flame.images.load('item_pack.png'),
      srcSize: Vector2(24, 24),
    );

    // 為每個物品加載對應的圖標
    for (final item in inventory.items) {
      item.sprite = spriteSheet.getSprite(item.spriteX, item.spriteY);
    }

    // 為裝備中的物品也加載圖標
    for (final equipSlot in equipment.slots.keys) {
      final item = equipment.slots[equipSlot];
      if (item != null && item.sprite == null) {
        item.sprite = spriteSheet.getSprite(item.spriteX, item.spriteY);
      }
    }

    // 設置背包UI的大小和位置 - 考慮裝備區域和角色狀態面板
    size = Vector2(
      itemsPerRow * (itemSize + spacing) + padding * 2 + 400, // 增加右側區域寬度
      ((inventory.maxSize / itemsPerRow).ceil()) * (itemSize + spacing) +
          padding * 2 +
          50, // 增加高度以適應角色狀態
    );

    // 居中顯示
    position = Vector2(
      game.size.x / 2 - size.x / 2,
      game.size.y / 2 - size.y / 2,
    );

    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isVisible) return;

    // 繪製背包背景
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final bgPaint =
        Paint()
          ..color = const Color(0xDD333333)
          ..style = PaintingStyle.fill;
    canvas.drawRect(bgRect, bgPaint);

    // 繪製邊框
    final borderPaint =
        Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(bgRect, borderPaint);

    // 繪製標題
    _drawText(
      canvas,
      '背包與角色狀態',
      Vector2(size.x / 2, padding),
      TextAlign.center,
      Colors.white,
      fontSize: 18,
    );

    // 繪製物品格子
    _drawItemSlots(canvas);

    // 繪製裝備區域
    _drawEquipmentSlots(canvas);

    // 繪製物品詳細說明
    _drawItemDetails(canvas);

    // 繪製角色狀態面板
    _drawCharacterStats(canvas);
  }

  /// 繪製物品格子
  void _drawItemSlots(Canvas canvas) {
    for (int i = 0; i < inventory.maxSize; i++) {
      final row = i ~/ itemsPerRow;
      final col = i % itemsPerRow;

      final x = padding + col * (itemSize + spacing);
      final y = padding + 30 + row * (itemSize + spacing); // 30 為標題高度

      // 繪製格子
      final slotRect = Rect.fromLTWH(x, y, itemSize, itemSize);
      final slotPaint =
          Paint()
            ..color =
                i == selectedItemIndex
                    ? const Color(0xFF555555)
                    : const Color(0xFF444444)
            ..style = PaintingStyle.fill;
      canvas.drawRect(slotRect, slotPaint);

      final slotBorderPaint =
          Paint()
            ..color =
                i == hoveredItemIndex ? Colors.yellow : Colors.grey.shade600
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;
      canvas.drawRect(slotRect, slotBorderPaint);

      // 如果格子有物品，則繪製物品
      if (i < inventory.items.length) {
        final item = inventory.items[i];

        // 繪製物品圖示
        item.sprite?.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2(itemSize, itemSize),
        );

        // 繪製物品名稱
        _drawText(
          canvas,
          item.name,
          Vector2(x + itemSize / 2, y + itemSize - 10),
          TextAlign.center,
          item.rarityColor,
          fontSize: 12,
        );

        // 如果是可堆疊物品且數量大於1，則顯示數量
        if (item.isStackable && item.quantity > 1) {
          _drawText(
            canvas,
            item.quantity.toString(),
            Vector2(x + itemSize - 5, y + 15),
            TextAlign.right,
            Colors.white,
            fontSize: 14,
            bold: true,
          );
        }
      }
    }
  }

  /// 繪製裝備區域
  void _drawEquipmentSlots(Canvas canvas) {
    final equipSlots = equipment.slots.keys.toList();
    for (int i = 0; i < equipSlots.length; i++) {
      final slot = equipSlots[i];
      final x = size.x - 200 + padding; // 裝備區域的X位置
      final y = padding + 30 + i * (itemSize + spacing); // 裝備區域的Y位置

      // 繪製裝備格子
      final slotRect = Rect.fromLTWH(x, y, itemSize, itemSize);
      final slotPaint =
          Paint()
            ..color =
                slot == selectedEquipSlot
                    ? const Color(0xFF555555)
                    : const Color(0xFF444444)
            ..style = PaintingStyle.fill;
      canvas.drawRect(slotRect, slotPaint);

      final slotBorderPaint =
          Paint()
            ..color =
                slot == hoveredEquipSlot ? Colors.yellow : Colors.grey.shade600
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;
      canvas.drawRect(slotRect, slotBorderPaint);

      // 如果格子有裝備，則繪製裝備
      final equipItem = equipment.slots[slot];
      if (equipItem != null) {
        // 繪製裝備圖示
        equipItem.sprite?.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2(itemSize, itemSize),
        );

        // 繪製裝備名稱
        _drawText(
          canvas,
          equipItem.name,
          Vector2(x + itemSize / 2, y + itemSize - 10),
          TextAlign.center,
          equipItem.rarityColor,
          fontSize: 12,
        );
      }
    }
  }

  /// 繪製角色狀態面板
  void _drawCharacterStats(Canvas canvas) {
    final Player player = game.player;

    // 角色狀態區域
    final statsX = size.x - 180;
    double y = padding * 3;

    // 繪製分隔線
    final dividerPaint =
        Paint()
          ..color = Colors.grey.shade600
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawLine(
      Offset(statsX - 10, padding * 2),
      Offset(statsX - 10, size.y - padding * 2),
      dividerPaint,
    );

    // 繪製角色狀態標題
    _drawText(
      canvas,
      '角色狀態',
      Vector2(statsX + 80, padding * 2),
      TextAlign.center,
      titleColor,
      fontSize: 18,
      bold: true,
    );

    y += lineHeight * 1.5;

    // 生命值
    _drawStatLine(
      canvas,
      '生命值',
      '${player.currentHealth.toInt()}/${player.maxHealth.toInt()}',
      statsX,
      y,
    );
    y += lineHeight;

    // 魔力值
    _drawStatLine(
      canvas,
      '魔力值',
      '${player.currentMana.toInt()}/${player.maxMana.toInt()}',
      statsX,
      y,
    );
    y += lineHeight;

    // 攻擊力
    _drawStatLine(canvas, '攻擊力', player.attack.toStringAsFixed(1), statsX, y);
    y += lineHeight;

    // 防禦力
    _drawStatLine(canvas, '防禦力', player.defense.toStringAsFixed(1), statsX, y);
    y += lineHeight;

    // 速度
    _drawStatLine(canvas, '速度', player.speed.toStringAsFixed(1), statsX, y);
    y += lineHeight;

    // 等級和經驗
    _drawStatLine(canvas, '等級', '${player.level}', statsX, y);
    y += lineHeight;

    _drawStatLine(
      canvas,
      '經驗值',
      '${player.experience}/${player.experienceToNextLevel}',
      statsX,
      y,
    );
    y += lineHeight * 1.5;

    // 裝備加成區塊
    _drawText(
      canvas,
      '裝備加成',
      Vector2(statsX, y),
      TextAlign.left,
      titleColor,
      fontSize: 16,
      bold: true,
    );

    y += lineHeight * 1.2;

    // 獲取所有裝備的總加成
    final equipStats = player.equipment.getTotalStats();

    // 攻擊加成
    final attackBonus = equipStats['attack'] ?? 0;
    if (attackBonus != 0) {
      _drawStatLine(
        canvas,
        '攻擊加成',
        (attackBonus > 0 ? '+' : '') + attackBonus.toStringAsFixed(1),
        statsX,
        y,
        valueColor: attackBonus > 0 ? Colors.green : Colors.red,
      );
      y += lineHeight;
    }

    // 防禦加成
    final defenseBonus = equipStats['defense'] ?? 0;
    if (defenseBonus != 0) {
      _drawStatLine(
        canvas,
        '防禦加成',
        (defenseBonus > 0 ? '+' : '') + defenseBonus.toStringAsFixed(1),
        statsX,
        y,
        valueColor: defenseBonus > 0 ? Colors.green : Colors.red,
      );
      y += lineHeight;
    }

    // 速度加成
    final speedBonus = equipStats['speed'] ?? 0;
    if (speedBonus != 0) {
      _drawStatLine(
        canvas,
        '速度加成',
        (speedBonus > 0 ? '+' : '') + speedBonus.toStringAsFixed(1),
        statsX,
        y,
        valueColor: speedBonus > 0 ? Colors.green : Colors.red,
      );
      y += lineHeight;
    }

    // 生命加成
    final healthBonus = equipStats['maxHealth'] ?? 0;
    if (healthBonus != 0) {
      _drawStatLine(
        canvas,
        '生命加成',
        (healthBonus > 0 ? '+' : '') + healthBonus.toStringAsFixed(1),
        statsX,
        y,
        valueColor: healthBonus > 0 ? Colors.green : Colors.red,
      );
      y += lineHeight;
    }

    // 魔力加成
    final manaBonus = equipStats['maxMana'] ?? 0;
    if (manaBonus != 0) {
      _drawStatLine(
        canvas,
        '魔力加成',
        (manaBonus > 0 ? '+' : '') + manaBonus.toStringAsFixed(1),
        statsX,
        y,
        valueColor: manaBonus > 0 ? Colors.green : Colors.red,
      );
      y += lineHeight;
    }
  }

  /// 繪製屬性行 (給角色面板使用)
  void _drawStatLine(
    Canvas canvas,
    String label,
    String value,
    double x,
    double y, {
    Color? valueColor,
  }) {
    // 繪製屬性名稱
    _drawText(
      canvas,
      '$label:',
      Vector2(x, y),
      TextAlign.left,
      Colors.white,
      fontSize: 14,
    );

    // 繪製屬性值
    _drawText(
      canvas,
      value,
      Vector2(x + 160, y),
      TextAlign.right,
      valueColor ?? this.valueColor,
      fontSize: 14,
      bold: true,
    );
  }

  /// 繪製選中物品的詳細信息
  void _drawItemDetails(Canvas canvas) {
    if (selectedItemIndex == null ||
        selectedItemIndex! >= inventory.items.length) {
      return;
    }

    final item = inventory.items[selectedItemIndex!];
    final detailX = padding;
    final detailY = size.y - 80; // 底部留出空間顯示詳情

    // 繪製詳情背景
    final detailRect = Rect.fromLTWH(
      detailX,
      detailY,
      size.x - padding * 2,
      70,
    );
    final detailPaint =
        Paint()
          ..color = const Color(0xFF222222)
          ..style = PaintingStyle.fill;
    canvas.drawRect(detailRect, detailPaint);

    // 繪製物品名稱
    _drawText(
      canvas,
      item.name,
      Vector2(detailX + 10, detailY + 15),
      TextAlign.left,
      item.rarityColor,
      fontSize: 16,
      bold: true,
    );

    // 繪製物品描述
    _drawText(
      canvas,
      item.description,
      Vector2(detailX + 10, detailY + 35),
      TextAlign.left,
      Colors.white,
      fontSize: 12,
    );

    // 繪製使用提示
    _drawText(
      canvas,
      '點擊物品使用',
      Vector2(detailX + 10, detailY + 55),
      TextAlign.left,
      Colors.yellow,
      fontSize: 12,
    );
  }

  /// 文字繪製輔助方法
  void _drawText(
    Canvas canvas,
    String text,
    Vector2 position,
    TextAlign align,
    Color color, {
    double fontSize = 16,
    bool bold = false,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Cubic11', // 設置字體以匹配遊戲風格
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    double x = position.x;
    if (align == TextAlign.center) {
      x -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      x -= textPainter.width;
    }

    textPainter.paint(canvas, Offset(x, position.y - textPainter.height / 2));
  }

  /// 鼠標點擊事件處理
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (!isVisible) return;

    // 獲取點擊的相對位置
    final localPosition = event.localPosition;

    // 計算點擊的物品索引
    final itemIndex = _getItemIndexAtPosition(localPosition);

    if (itemIndex != null) {
      // 如果點擊已選中的物品，則使用它
      if (itemIndex == selectedItemIndex &&
          itemIndex < inventory.items.length) {
        inventory.useItem(itemIndex);
      }
      // 否則選中該物品
      else {
        selectedItemIndex = itemIndex;
      }
    }
  }

  /// 鼠標移動事件處理
  void onPointerMove(Vector2 position) {
    if (!isVisible) return;

    final localPosition = position - this.position;
    hoveredItemIndex = _getItemIndexAtPosition(localPosition);
  }

  /// 根據位置獲取物品索引
  int? _getItemIndexAtPosition(Vector2 position) {
    final x = position.x;
    final y = position.y;

    // 確保在背包範圍內
    if (x < padding ||
        x > size.x - padding ||
        y < padding + 30 ||
        y > size.y - 80) {
      return null;
    }

    final col = ((x - padding) / (itemSize + spacing)).floor();
    final row = ((y - padding - 30) / (itemSize + spacing)).floor();

    if (col < 0 || col >= itemsPerRow || row < 0) return null;

    final index = row * itemsPerRow + col;
    if (index < 0 || index >= inventory.maxSize) return null;

    return index;
  }

  /// 處理鍵盤事件
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // 使用數字鍵1-9快速使用物品
    if (isVisible && event is KeyDownEvent) {
      final keyNumber = _getNumberFromKey(event.logicalKey);
      if (keyNumber != null &&
          keyNumber > 0 &&
          keyNumber <= inventory.items.length) {
        inventory.useItem(keyNumber - 1);
        return true;
      }
    }

    return false;
  }

  /// 從按鍵獲取數字（1-9）
  int? _getNumberFromKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit1) return 1;
    if (key == LogicalKeyboardKey.digit2) return 2;
    if (key == LogicalKeyboardKey.digit3) return 3;
    if (key == LogicalKeyboardKey.digit4) return 4;
    if (key == LogicalKeyboardKey.digit5) return 5;
    if (key == LogicalKeyboardKey.digit6) return 6;
    if (key == LogicalKeyboardKey.digit7) return 7;
    if (key == LogicalKeyboardKey.digit8) return 8;
    if (key == LogicalKeyboardKey.digit9) return 9;
    return null;
  }

  /// 打開背包
  void open() {
    isVisible = true;
  }

  /// 關閉背包
  void close() {
    isVisible = false;
    selectedItemIndex = null;
    hoveredItemIndex = null;
  }

  /// 切換背包開關狀態
  void toggle() {
    isVisible ? close() : open();
  }
}
