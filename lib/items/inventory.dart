// filepath: d:\game\night_and_rain\lib\items\inventory.dart
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../player.dart';
import 'item.dart';

/// 背包系統類
class Inventory {
  final List<Item> items = []; // 背包中的物品
  final int maxSize; // 背包最大容量
  bool isOpen = false; // 背包是否開啟
  final Player player; // 關聯的玩家實例

  Inventory({required this.player, this.maxSize = 20});

  /// 檢查背包是否已滿
  bool get isFull => items.length >= maxSize;

  /// 取得背包中物品數量
  int get itemCount => items.length;

  /// 添加物品到背包
  /// 如果物品可堆疊，會嘗試與現有物品堆疊
  /// 返回是否成功添加
  bool addItem(Item item) {
    // 如果背包已滿且無法堆疊，則不添加
    if (isFull && !_canStack(item)) return false;

    // 先嘗試堆疊
    if (item.isStackable) {
      final existingItem = items.firstWhereOrNull(
        (i) => i.id == item.id && i.quantity < i.maxStackSize,
      );

      if (existingItem != null) {
        // 計算能夠堆疊的數量
        final spaceLeft = existingItem.maxStackSize - existingItem.quantity;
        final stackAmount = min(spaceLeft, item.quantity);

        existingItem.quantity += stackAmount;
        item.quantity -= stackAmount;

        // 如果還有剩餘，且背包未滿，則添加新物品
        if (item.quantity > 0 && !isFull) {
          final newItem = item.copyWith();
          items.add(newItem);
        }

        return true;
      }
    }

    // 如果無法堆疊或找不到相同物品，則添加新物品
    if (!isFull) {
      final newItem = item.copyWith();
      items.add(newItem);
      return true;
    }

    return false;
  }

  /// 從背包中移除物品
  bool removeItem(String itemId, {int quantity = 1}) {
    // 找到對應物品
    final itemIndex = items.indexWhere((i) => i.id == itemId);
    if (itemIndex < 0) return false;

    final item = items[itemIndex];

    // 如果移除數量小於或等於物品數量
    if (quantity < item.quantity) {
      item.quantity -= quantity;
      return true;
    }
    // 如果移除數量大於或等於物品數量，則移除整個物品
    else {
      items.removeAt(itemIndex);
      return true;
    }
  }

  /// 使用指定位置的物品
  bool useItem(int index) {
    if (index < 0 || index >= items.length) return false;

    final item = items[index];
    final result = item.use(player);

    // 如果使用成功且數量為0，則移除物品
    if (result && item.quantity <= 0) {
      items.removeAt(index);
    }

    return result;
  }

  /// 根據類型過濾物品
  List<Item> filterByType(ItemType type) {
    return items.where((item) => item.type == type).toList();
  }

  /// 清空背包
  void clear() {
    items.clear();
  }

  /// 檢查物品是否可以堆疊
  bool _canStack(Item newItem) {
    if (!newItem.isStackable) return false;

    return items.any(
      (item) => item.id == newItem.id && item.quantity < item.maxStackSize,
    );
  }
}

/// 背包UI組件
class InventoryUI extends PositionComponent
    with TapCallbacks, KeyboardHandler, HasGameReference<NightAndRainGame> {
  final Inventory inventory;
  final double padding = 10.0;
  final double itemSize = 60.0;
  final double spacing = 5.0;
  int itemsPerRow = 5;

  // UI 狀態
  bool isVisible = false;
  int? hoveredItemIndex;
  int? selectedItemIndex;

  InventoryUI({required this.inventory}) : super(priority: 100);

  @override
  Future<void> onLoad() async {
    // 設置背包UI的大小和位置
    size = Vector2(
      itemsPerRow * (itemSize + spacing) + padding * 2,
      ((inventory.maxSize / itemsPerRow).ceil()) * (itemSize + spacing) +
          padding * 2,
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
      '背包 (${inventory.itemCount}/${inventory.maxSize})',
      Vector2(size.x / 2, padding),
      TextAlign.center,
      Colors.white,
      fontSize: 18,
    );

    // 繪製物品格子
    _drawItemSlots(canvas);

    // 繪製物品詳細說明
    _drawItemDetails(canvas);
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

  /// 繪製選中物品的詳細信息
  void _drawItemDetails(Canvas canvas) {
    if (selectedItemIndex == null ||
        selectedItemIndex! >= inventory.items.length)
      return;

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
    // 移除切換背包顯示的部分，因為現在由 NightAndRainGame 處理
    // if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
    //   isVisible = !isVisible;
    //   if (!isVisible) {
    //     selectedItemIndex = null;
    //     hoveredItemIndex = null;
    //   }
    //   return true;
    // }

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
