import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../components/items/inventory.dart';
import '../components/items/equipment.dart';
import '../components/items/item.dart';
import '../controllers/inventory_ui_controller.dart';
import '../player.dart';
import '../utils/ui_utils.dart';

/// 美化版背包 UI 視圖類
class InventoryUI extends PositionComponent
    with
        TapCallbacks,
        HoverCallbacks,
        KeyboardHandler,
        HasGameReference<NightAndRainGame> {
  // 視圖設置和狀態
  final double padding = 12.0; // 增加邊距提高可讀性
  final double itemSize = 64.0; // 略微增大物品格子
  final double spacing = 6.0; // 稍微增加間距
  final int itemsPerRow = 5;

  // UI 顏色主題
  final Color backgroundColor = const Color(0xDD222233); // 深藍灰背景
  final Color selectedColor = const Color(0xFF4466AA); // 藍色選中色
  final Color hoverColor = Colors.amber; // 琥珀色懸停色
  final Color borderColor = const Color(0xFF6688CC); // 亮藍色邊框
  final Color textColor = Colors.white;
  final Color titleColor = const Color(0xFFFFD700); // 金色標題
  final Color accentColor = const Color(0xFF66CCFF); // 亮藍色強調

  // 反饋動畫相關
  double _selectionPulse = 0.0;
  bool _pulseIncreasing = true;
  final double _pulseSpeed = 2.0;

  // 物品使用提示動畫
  double _hintOpacity = 0.0;
  bool _showingHint = false;
  String _hintText = "";
  int? _lastSelectedIndex;

  // 懸停元素視圖狀態
  int? hoveredItemIndex;
  String? hoveredEquipSlot;

  // 控制器相關
  final Inventory _inventory;
  final Equipment _equipment;
  InventoryUIController? _controller;
  bool _isInitialized = false;

  InventoryUI({required Inventory inventory, required Equipment equipment})
    : _inventory = inventory,
      _equipment = equipment,
      super(priority: 100);

  InventoryUIController get controller {
    if (_controller == null) {
      if (!_isInitialized) {
        debugPrint("【警告】組件尚未完全初始化，無法安全地創建控制器");
        throw Exception("嘗試訪問未初始化的控制器：組件尚未附加到遊戲實例或尚未完成初始化");
      }

      try {
        debugPrint("初始化庫存UI控制器");
        _controller = InventoryUIController(
          game: game,
          inventory: _inventory,
          equipment: _equipment,
        );
      } catch (e) {
        debugPrint("【嚴重錯誤】無法創建控制器: $e");
        throw Exception("無法創建庫存UI控制器: $e");
      }
    }
    return _controller!;
  }

  @override
  Future<void> onLoad() async {
    try {
      // 初始化控制器
      _controller = InventoryUIController(
        game: game,
        inventory: _inventory,
        equipment: _equipment,
      );
      _isInitialized = true;

      // 加載精靈圖
      final spriteSheet = SpriteSheet(
        image: await Flame.images.load('item_pack.png'),
        srcSize: Vector2(24, 24),
      );

      // 為每個物品加載圖標
      for (final item in _inventory.items) {
        item.sprite = spriteSheet.getSprite(item.spriteX, item.spriteY);
      }

      // 為裝備中的物品加載圖標
      for (final equipSlot in _equipment.slots.keys) {
        final item = _equipment.slots[equipSlot];
        if (item != null && item.sprite == null) {
          item.sprite = spriteSheet.getSprite(item.spriteX, item.spriteY);
        }
      }

      // 設置背包UI的大小和位置
      size = Vector2(
        itemsPerRow * (itemSize + spacing) + padding * 2 + 400,
        ((controller.inventory.maxSize / itemsPerRow).ceil()) *
                (itemSize + spacing) +
            padding * 2 +
            80, // 增加高度，給物品詳情留出更多空間
      );

      // 居中顯示
      position = Vector2(
        game.size.x / 2 - size.x / 2,
        game.size.y / 2 - size.y / 2,
      );
    } catch (e) {
      debugPrint("【錯誤】初始化 InventoryUI 失敗: $e");
    }

    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新選中物品的脈動動畫
    if (_pulseIncreasing) {
      _selectionPulse += dt * _pulseSpeed;
      if (_selectionPulse >= 1.0) {
        _selectionPulse = 1.0;
        _pulseIncreasing = false;
      }
    } else {
      _selectionPulse -= dt * _pulseSpeed;
      if (_selectionPulse <= 0.0) {
        _selectionPulse = 0.0;
        _pulseIncreasing = true;
      }
    }

    // 更新提示動畫
    if (_showingHint) {
      _hintOpacity = math.min(1.0, _hintOpacity + dt * 3.0);
    } else {
      _hintOpacity = math.max(0.0, _hintOpacity - dt * 3.0);
    }

    // 檢查選中物品變化
    if (controller.selectedItemIndex != _lastSelectedIndex) {
      _lastSelectedIndex = controller.selectedItemIndex;
      if (_lastSelectedIndex != null) {
        // 顯示提示動畫
        final item = controller.inventory.items[_lastSelectedIndex!];
        _hintText = item.isEquippable ? "按 E 鍵裝備" : "按 E 鍵使用";
        _showingHint = true;
        Future.delayed(Duration(seconds: 2), () {
          _showingHint = false;
        });
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 不可見時不渲染
    if (!controller.isVisible) return;

    // 繪製畫面
    _drawBackground(canvas);
    _drawTitle(canvas);
    _drawItemSlots(canvas);
    _drawEquipmentSlots(canvas);
    _drawItemDetails(canvas);
    _drawCharacterStats(canvas);

    // 繪製提示動畫
    if (_hintOpacity > 0 && controller.selectedItemIndex != null) {
      _drawActionHint(canvas);
    }
  }

  /// 繪製背景和邊框
  void _drawBackground(Canvas canvas) {
    // 使用漸變背景
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);

    // 創建漸變色彩
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [backgroundColor, backgroundColor.withOpacity(0.95)],
    );

    // 繪製帶圓角的背景
    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(15.0));

    // 先畫陰影
    canvas.drawRRect(
      rrect.shift(const Offset(4, 4)),
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    // 然後畫主要背景
    canvas.drawRRect(rrect, Paint()..shader = gradient.createShader(bgRect));

    // 最後畫邊框
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  /// 繪製標題
  void _drawTitle(Canvas canvas) {
    // 使用陰影和更大字號
    UIUtils.drawText(
      canvas,
      '背包與角色狀態',
      Vector2(size.x / 2, padding + 5),
      align: TextAlign.center,
      color: titleColor,
      fontSize: 24,
      bold: true,
      // 需要在UIUtils中添加這個參數
    );

    // 在標題下方添加分隔線
    final lineY = padding + 35;
    final linePaint =
        Paint()
          ..color = borderColor.withOpacity(0.7)
          ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(padding * 2, lineY),
      Offset(size.x - padding * 2, lineY),
      linePaint,
    );
  }

  /// 繪製物品格子
  void _drawItemSlots(Canvas canvas) {
    for (int i = 0; i < controller.inventory.maxSize; i++) {
      final row = i ~/ itemsPerRow;
      final col = i % itemsPerRow;

      final x = padding + col * (itemSize + spacing);
      final y = padding + 45 + row * (itemSize + spacing); // 45為標題和分隔線的高度

      // 判斷是否選中或懸停
      final isSelected = i == controller.selectedItemIndex;
      final isHovered = i == hoveredItemIndex;

      // 繪製有陰影的格子
      _drawItemSlot(canvas, x, y, isSelected, isHovered, i);
    }
  }

  /// 繪製單個物品格子
  void _drawItemSlot(
    Canvas canvas,
    double x,
    double y,
    bool isSelected,
    bool isHovered,
    int index,
  ) {
    final slotRect = Rect.fromLTWH(x, y, itemSize, itemSize);

    // 基本格子顏色
    Color bgColor = const Color(0xFF333344);
    if (isSelected) {
      // 選中時使用脈動顏色
      final pulseColor =
          Color.lerp(
            selectedColor,
            selectedColor.withValues(alpha: 0.65),
            _selectionPulse,
          )!;
      bgColor = pulseColor;
    }

    // 畫出圓角矩形作為格子
    final rrect = RRect.fromRectAndRadius(slotRect, const Radius.circular(6.0));

    // 先畫陰影
    if (isSelected || isHovered) {
      canvas.drawRRect(
        rrect.shift(const Offset(2, 2)),
        Paint()..color = Colors.black.withOpacity(0.3),
      );
    }

    // 繪製格子背景
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // 繪製格子邊框
    canvas.drawRRect(
      rrect,
      Paint()
        ..color =
            isHovered
                ? hoverColor
                : (isSelected
                    ? selectedColor.withValues(alpha: 0.8)
                    : Colors.grey.shade700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected || isHovered ? 2.0 : 1.0,
    );

    // 如果格子有物品，則繪製物品
    if (index < controller.inventory.items.length) {
      final item = controller.inventory.items[index];

      // 在物品下方繪製圓形高亮
      if (isSelected) {
        canvas.drawCircle(
          Offset(x + itemSize / 2, y + itemSize / 2),
          itemSize / 2 - 8,
          Paint()
            ..color = item.rarityColor.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
      }

      // 繪製物品圖示
      item.sprite?.render(
        canvas,
        position: Vector2(
          x + itemSize / 2 - itemSize * 0.35,
          y + itemSize / 2 - itemSize * 0.35,
        ),
        size: Vector2(itemSize * 0.7, itemSize * 0.7),
      );

      // 繪製物品名稱背景
      final textBgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, y + itemSize - 18, itemSize - 4, 16),
        const Radius.circular(4.0),
      );

      canvas.drawRRect(
        textBgRect,
        Paint()..color = Colors.black.withOpacity(0.6),
      );

      // 繪製物品名稱
      UIUtils.drawText(
        canvas,
        item.name,
        Vector2(x + itemSize / 2, y + itemSize - 10),
        align: TextAlign.center,
        color: item.rarityColor,
        fontSize: 12,
      );

      // 如果是可堆疊物品且數量大於1，則顯示數量
      if (item.isStackable && item.quantity > 1) {
        // 先畫一個小背景
        final countBgRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + itemSize - 22, y + 2, 20, 18),
          const Radius.circular(4.0),
        );

        canvas.drawRRect(
          countBgRect,
          Paint()..color = Colors.black.withOpacity(0.6),
        );

        // 再畫數量文字
        UIUtils.drawText(
          canvas,
          item.quantity.toString(),
          Vector2(x + itemSize - 12, y + 11),
          align: TextAlign.center,
          color: Colors.white,
          fontSize: 12,
          bold: true,
        );
      }

      // 如果物品稀有度高，添加閃光效果
      if (item.rarity.index >= 2) {
        // rare或以上
        // 閃光效果透明度隨脈動變化
        final glowOpacity = 0.3 + _selectionPulse * 0.4;

        canvas.drawCircle(
          Offset(x + itemSize / 2, y + itemSize / 2),
          itemSize / 2 - 4,
          Paint()
            ..color = item.rarityColor.withOpacity(glowOpacity * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    }
  }

  /// 繪製裝備區域
  void _drawEquipmentSlots(Canvas canvas) {
    final equipSlots = controller.equipment.slots.keys.toList();

    // 先畫裝備區域背景面板
    final equipBackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.x - 220,
        padding + 45,
        200,
        equipSlots.length * (itemSize + spacing) + padding,
      ),
      const Radius.circular(8.0),
    );

    canvas.drawRRect(
      equipBackRect,
      Paint()..color = backgroundColor.withOpacity(0.5),
    );

    canvas.drawRRect(
      equipBackRect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 繪製"裝備"標題
    UIUtils.drawText(
      canvas,
      '角色裝備',
      Vector2(size.x - 120, padding + 55),
      align: TextAlign.center,
      color: titleColor,
      fontSize: 18,
      bold: true,
    );

    // 繪製各裝備槽位
    for (int i = 0; i < equipSlots.length; i++) {
      final slot = equipSlots[i];
      final x = size.x - 200 + padding; // 裝備區域的X位置
      final y = padding + 85 + i * (itemSize + spacing); // 裝備區域的Y位置

      // 繪製槽位名稱
      UIUtils.drawText(
        canvas,
        '${_getSlotDisplayName(slot)}:',
        Vector2(x, y + itemSize / 2),
        align: TextAlign.left,
        color: Colors.white,
        fontSize: 14,
      );

      // 判斷槽位狀態
      final isSelected = slot == controller.selectedEquipSlot;
      final isHovered = slot == hoveredEquipSlot;

      // 繪製裝備槽
      _drawEquipSlot(canvas, x + 90, y, isSelected, isHovered, slot);
    }
  }

  /// 繪製單個裝備槽
  void _drawEquipSlot(
    Canvas canvas,
    double x,
    double y,
    bool isSelected,
    bool isHovered,
    String slot,
  ) {
    final slotRect = Rect.fromLTWH(x, y, itemSize, itemSize);

    // 基本格子顏色
    Color bgColor = const Color(0xFF333344);
    if (isSelected) {
      // 選中時使用脈動顏色
      final pulseColor =
          Color.lerp(
            selectedColor,
            selectedColor.withValues(alpha: 0.65),
            _selectionPulse,
          )!;
      bgColor = pulseColor;
    }

    // 畫出圓角矩形作為格子
    final rrect = RRect.fromRectAndRadius(slotRect, const Radius.circular(6.0));

    // 先畫陰影
    if (isSelected || isHovered) {
      canvas.drawRRect(
        rrect.shift(const Offset(2, 2)),
        Paint()..color = Colors.black.withOpacity(0.3),
      );
    }

    // 繪製格子背景
    canvas.drawRRect(rrect, Paint()..color = bgColor);

    // 繪製格子邊框
    canvas.drawRRect(
      rrect,
      Paint()
        ..color =
            isHovered
                ? hoverColor
                : (isSelected
                    ? selectedColor.withValues(alpha: 0.8)
                    : Colors.grey.shade700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected || isHovered ? 2.0 : 1.0,
    );

    // 如果有裝備，繪製裝備
    final equipItem = controller.equipment.slots[slot];
    if (equipItem != null) {
      // 繪製裝備圖示
      equipItem.sprite?.render(
        canvas,
        position: Vector2(
          x + itemSize / 2 - itemSize * 0.35,
          y + itemSize / 2 - itemSize * 0.35,
        ),
        size: Vector2(itemSize * 0.7, itemSize * 0.7),
      );

      // 繪製裝備名稱背景
      final textBgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, y + itemSize - 18, itemSize - 4, 16),
        const Radius.circular(4.0),
      );

      canvas.drawRRect(
        textBgRect,
        Paint()..color = Colors.black.withOpacity(0.6),
      );

      // 繪製裝備名稱
      UIUtils.drawText(
        canvas,
        equipItem.name,
        Vector2(x + itemSize / 2, y + itemSize - 10),
        align: TextAlign.center,
        color: equipItem.rarityColor,
        fontSize: 12,
      );

      // 如果裝備稀有度高，添加閃光效果
      if (equipItem.rarity.index >= 2) {
        // rare或以上
        // 閃光效果透明度隨脈動變化
        final glowOpacity = 0.3 + _selectionPulse * 0.4;

        canvas.drawCircle(
          Offset(x + itemSize / 2, y + itemSize / 2),
          itemSize / 2 - 4,
          Paint()
            ..color = equipItem.rarityColor.withOpacity(glowOpacity * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    } else {
      // 如果沒有裝備，顯示空槽位圖示
      canvas.drawLine(
        Offset(x + 10, y + 10),
        Offset(x + itemSize - 10, y + itemSize - 10),
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..strokeWidth = 2.0,
      );

      canvas.drawLine(
        Offset(x + itemSize - 10, y + 10),
        Offset(x + 10, y + itemSize - 10),
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..strokeWidth = 2.0,
      );
    }
  }

  /// 繪製角色狀態面板
  void _drawCharacterStats(Canvas canvas) {
    final Player player = game.player;

    // 繪製角色狀態面板背景
    final statsBackRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.x - 220,
        padding +
            45 +
            controller.equipment.slots.length * (itemSize + spacing) +
            padding +
            10,
        200,
        size.y -
            (padding +
                45 +
                controller.equipment.slots.length * (itemSize + spacing) +
                padding +
                10) -
            90,
      ),
      const Radius.circular(8.0),
    );

    canvas.drawRRect(
      statsBackRect,
      Paint()..color = backgroundColor.withOpacity(0.5),
    );

    canvas.drawRRect(
      statsBackRect,
      Paint()
        ..color = borderColor.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 角色狀態區域起始位置
    final statsX = size.x - 210;
    double y = statsBackRect.top + 20;

    // 繪製角色狀態標題
    UIUtils.drawText(
      canvas,
      '角色狀態',
      Vector2(size.x - 120, y),
      align: TextAlign.center,
      color: titleColor,
      fontSize: 18,
      bold: true,
    );

    y += 25;

    // 繪製分隔線
    canvas.drawLine(
      Offset(statsX, y),
      Offset(statsX + 180, y),
      Paint()
        ..color = borderColor.withOpacity(0.5)
        ..strokeWidth = 1.0,
    );

    y += 15;

    // 繪製基礎屬性
    _drawStatBar(
      canvas,
      '生命值',
      player.currentHealth / player.maxHealth,
      '${player.currentHealth.toInt()}/${player.maxHealth.toInt()}',
      statsX,
      y,
      Colors.red,
    );
    y += 25;

    _drawStatBar(
      canvas,
      '魔力值',
      player.currentMana / player.maxMana,
      '${player.currentMana.toInt()}/${player.maxMana.toInt()}',
      statsX,
      y,
      Colors.blue,
    );
    y += 25;

    // 攻擊力
    _drawStat(
      canvas,
      '攻擊力',
      player.attack.toStringAsFixed(1),
      statsX,
      y,
      accentColor,
    );
    y += 20;

    // 防禦力
    _drawStat(
      canvas,
      '防禦力',
      player.defense.toStringAsFixed(1),
      statsX,
      y,
      accentColor,
    );
    y += 20;

    // 速度
    _drawStat(
      canvas,
      '速度',
      player.speed.toStringAsFixed(1),
      statsX,
      y,
      accentColor,
    );
    y += 20;

    // 等級和經驗
    _drawStat(canvas, '等級', '${player.level}', statsX, y, accentColor);
    y += 20;

    // 經驗值進度條
    _drawExpBar(
      canvas,
      player.experience / player.experienceToNextLevel,
      '經驗: ${player.experience}/${player.experienceToNextLevel}',
      statsX,
      y,
      Colors.green,
    );

    y += 30;

    // 裝備加成區塊
    if (player.equipment.getTotalStats().isNotEmpty) {
      UIUtils.drawText(
        canvas,
        '裝備加成',
        Vector2(statsX + 90, y),
        align: TextAlign.center,
        color: titleColor,
        fontSize: 16,
        bold: true,
      );

      y += 20;

      // 繪製分隔線
      canvas.drawLine(
        Offset(statsX, y),
        Offset(statsX + 180, y),
        Paint()
          ..color = borderColor.withOpacity(0.5)
          ..strokeWidth = 1.0,
      );

      y += 15;

      // 獲取所有裝備的總加成
      final equipStats = player.equipment.getTotalStats();

      // 攻擊加成
      final attackBonus = equipStats['attack'] ?? 0;
      if (attackBonus != 0) {
        _drawBonusStat(
          canvas,
          '攻擊加成',
          (attackBonus > 0 ? '+' : '') + attackBonus.toStringAsFixed(1),
          statsX,
          y,
          attackBonus > 0 ? Colors.green : Colors.red,
        );
        y += 20;
      }

      // 防禦加成
      final defenseBonus = equipStats['defense'] ?? 0;
      if (defenseBonus != 0) {
        _drawBonusStat(
          canvas,
          '防禦加成',
          (defenseBonus > 0 ? '+' : '') + defenseBonus.toStringAsFixed(1),
          statsX,
          y,
          defenseBonus > 0 ? Colors.green : Colors.red,
        );
        y += 20;
      }

      // 速度加成
      final speedBonus = equipStats['speed'] ?? 0;
      if (speedBonus != 0) {
        _drawBonusStat(
          canvas,
          '速度加成',
          (speedBonus > 0 ? '+' : '') + speedBonus.toStringAsFixed(1),
          statsX,
          y,
          speedBonus > 0 ? Colors.green : Colors.red,
        );
        y += 20;
      }

      // 生命加成
      final healthBonus = equipStats['maxHealth'] ?? 0;
      if (healthBonus != 0) {
        _drawBonusStat(
          canvas,
          '生命加成',
          (healthBonus > 0 ? '+' : '') + healthBonus.toStringAsFixed(1),
          statsX,
          y,
          healthBonus > 0 ? Colors.green : Colors.red,
        );
        y += 20;
      }

      // 魔力加成
      final manaBonus = equipStats['maxMana'] ?? 0;
      if (manaBonus != 0) {
        _drawBonusStat(
          canvas,
          '魔力加成',
          (manaBonus > 0 ? '+' : '') + manaBonus.toStringAsFixed(1),
          statsX,
          y,
          manaBonus > 0 ? Colors.green : Colors.red,
        );
      }
    }
  }

  /// 繪製進度條樣式的屬性
  void _drawStatBar(
    Canvas canvas,
    String label,
    double ratio,
    String value,
    double x,
    double y,
    Color barColor,
  ) {
    // 標籤
    UIUtils.drawText(
      canvas,
      '$label:',
      Vector2(x, y + 10),
      align: TextAlign.left,
      color: Colors.white,
      fontSize: 14,
    );

    // 進度條背景
    final barBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 70, y, 110, 20),
      const Radius.circular(4.0),
    );

    canvas.drawRRect(barBgRect, Paint()..color = Colors.grey.shade800);

    // 進度條前景
    final barFgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 70, y, 110 * ratio.clamp(0.0, 1.0), 20),
      const Radius.circular(4.0),
    );

    // 創建漸變色彩
    final Gradient gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [barColor, barColor.withValues(alpha: 0.7)],
    );

    canvas.drawRRect(
      barFgRect,
      Paint()..shader = gradient.createShader(barFgRect.outerRect),
    );

    // 數值文字
    UIUtils.drawText(
      canvas,
      value,
      Vector2(x + 125, y + 10),
      align: TextAlign.center,
      color: Colors.white,
      fontSize: 12,
      bold: true,
    );
  }

  /// 繪製經驗值條
  void _drawExpBar(
    Canvas canvas,
    double ratio,
    String value,
    double x,
    double y,
    Color barColor,
  ) {
    // 進度條背景
    final barBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, 180, 15),
      const Radius.circular(4.0),
    );

    canvas.drawRRect(barBgRect, Paint()..color = Colors.grey.shade800);

    // 進度條前景
    final barFgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, 180 * ratio.clamp(0.0, 1.0), 15),
      const Radius.circular(4.0),
    );

    // 創建漸變色彩
    final Gradient gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [barColor, barColor.withValues(alpha: 0.7)],
    );

    canvas.drawRRect(
      barFgRect,
      Paint()..shader = gradient.createShader(barFgRect.outerRect),
    );

    // 數值文字
    UIUtils.drawText(
      canvas,
      value,
      Vector2(x + 90, y + 7.5),
      align: TextAlign.center,
      color: Colors.white,
      fontSize: 10,
      bold: true,
    );
  }

  /// 繪製普通屬性行
  void _drawStat(
    Canvas canvas,
    String label,
    String value,
    double x,
    double y,
    Color valueColor,
  ) {
    // 繪製屬性名稱
    UIUtils.drawText(
      canvas,
      '$label:',
      Vector2(x, y),
      align: TextAlign.left,
      color: Colors.white,
      fontSize: 14,
    );

    // 繪製屬性值背景
    final valueBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 70, y - 12, 110, 22),
      const Radius.circular(4.0),
    );

    canvas.drawRRect(
      valueBgRect,
      Paint()..color = Colors.black.withOpacity(0.2),
    );

    // 繪製屬性值
    UIUtils.drawText(
      canvas,
      value,
      Vector2(x + 125, y),
      align: TextAlign.center,
      color: valueColor,
      fontSize: 14,
      bold: true,
    );
  }

  /// 繪製加成屬性行
  void _drawBonusStat(
    Canvas canvas,
    String label,
    String value,
    double x,
    double y,
    Color valueColor,
  ) {
    // 繪製屬性名稱
    UIUtils.drawText(
      canvas,
      '$label:',
      Vector2(x, y),
      align: TextAlign.left,
      color: Colors.white,
      fontSize: 14,
    );

    // 繪製屬性值背景和邊框
    final valueBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 80, y - 12, 100, 22),
      const Radius.circular(4.0),
    );

    canvas.drawRRect(
      valueBgRect,
      Paint()..color = Colors.black.withOpacity(0.2),
    );

    canvas.drawRRect(
      valueBgRect,
      Paint()
        ..color = valueColor.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 繪製屬性值
    UIUtils.drawText(
      canvas,
      value,
      Vector2(x + 130, y),
      align: TextAlign.center,
      color: valueColor,
      fontSize: 14,
      bold: true,
    );
  }

  /// 繪製選中物品的詳細信息
  void _drawItemDetails(Canvas canvas) {
    if (controller.selectedItemIndex == null ||
        controller.selectedItemIndex! >= controller.inventory.items.length) {
      return;
    }

    final item = controller.inventory.items[controller.selectedItemIndex!];
    final detailX = padding;
    final detailY = size.y - 90; // 底部留出空間顯示詳情

    // 繪製物品詳情背景面板
    final detailRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(detailX, detailY, size.x - padding * 2, 80),
      const Radius.circular(8.0),
    );

    // 繪製漸變背景
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF333344), const Color(0xFF222233)],
    );

    canvas.drawRRect(
      detailRect,
      Paint()..shader = gradient.createShader(detailRect.outerRect),
    );

    // 繪製邊框
    canvas.drawRRect(
      detailRect,
      Paint()
        ..color = item.rarityColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 繪製物品圖標背景
    final iconBgRadius = 28.0;
    canvas.drawCircle(
      Offset(detailX + 40, detailY + 40),
      iconBgRadius,
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // 繪製物品圖標邊框
    canvas.drawCircle(
      Offset(detailX + 40, detailY + 40),
      iconBgRadius,
      Paint()
        ..color = item.rarityColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 繪製物品圖示
    item.sprite?.render(
      canvas,
      position: Vector2(detailX + 40 - 20, detailY + 40 - 20),
      size: Vector2(40, 40),
    );

    // 繪製物品名稱
    UIUtils.drawText(
      canvas,
      item.name,
      Vector2(detailX + 90, detailY + 20),
      align: TextAlign.left,
      color: item.rarityColor,
      fontSize: 18,
      bold: true,
    );

    // 繪製物品描述
    UIUtils.drawText(
      canvas,
      item.description,
      Vector2(detailX + 90, detailY + 45),
      align: TextAlign.left,
      color: Colors.white,
      fontSize: 14,
      maxWidth: size.x - 200, // 限制寬度，避免文字溢出
    );

    // 繪製物品詳細屬性
    if (item.stats != null && item.stats!.isNotEmpty) {
      double statX = size.x - 200;
      double statY = detailY + 20;

      item.stats!.forEach((key, value) {
        String statName =
            key == 'attack'
                ? '攻擊力'
                : key == 'defense'
                ? '防禦力'
                : key == 'speed'
                ? '速度'
                : key == 'maxHealth'
                ? '生命值'
                : key == 'maxMana'
                ? '魔力值'
                : key;

        UIUtils.drawText(
          canvas,
          '$statName: ${value > 0 ? "+" : ""}${value.toStringAsFixed(1)}',
          Vector2(statX, statY),
          align: TextAlign.left,
          color: value > 0 ? Colors.green : Colors.red,
          fontSize: 12,
          bold: true,
        );

        statY += 15;
      });
    }

    // 繪製操作提示
    _drawActionButtons(canvas, item, detailX, detailY);
  }

  /// 繪製物品操作按鈕
  void _drawActionButtons(
    Canvas canvas,
    Item item,
    double detailX,
    double detailY,
  ) {
    final actionText = item.isEquippable ? "裝備" : "使用";

    // 繪製使用/裝備按鈕
    final useButtonRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x - 280, detailY + 30, 80, 30),
      const Radius.circular(15.0),
    );

    // 按鈕背景
    canvas.drawRRect(
      useButtonRect,
      Paint()..color = accentColor.withOpacity(0.8),
    );

    // 按鈕文字
    UIUtils.drawText(
      canvas,
      actionText,
      Vector2(size.x - 240, detailY + 45),
      align: TextAlign.center,
      color: Colors.white,
      fontSize: 14,
      bold: true,
    );

    // 按鍵提示
    UIUtils.drawText(
      canvas,
      '(E)',
      Vector2(size.x - 210, detailY + 45),
      align: TextAlign.left,
      color: Colors.white.withOpacity(0.8),
      fontSize: 12,
    );

    // 繪製熱鍵綁定按鈕
    final bindButtonRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x - 180, detailY + 30, 100, 30),
      const Radius.circular(15.0),
    );

    // 按鈕背景
    canvas.drawRRect(
      bindButtonRect,
      Paint()..color = Colors.orange.withOpacity(0.8),
    );

    // 按鈕文字
    UIUtils.drawText(
      canvas,
      '設為熱鍵',
      Vector2(size.x - 130, detailY + 45),
      align: TextAlign.center,
      color: Colors.white,
      fontSize: 14,
      bold: true,
    );

    // 按鍵提示
    UIUtils.drawText(
      canvas,
      '(1-4)',
      Vector2(size.x - 90, detailY + 45),
      align: TextAlign.left,
      color: Colors.white.withOpacity(0.8),
      fontSize: 12,
    );
  }

  /// 繪製動作提示動畫
  void _drawActionHint(Canvas canvas) {
    if (controller.selectedItemIndex == null) return;

    final item = controller.inventory.items[controller.selectedItemIndex!];
    final row = controller.selectedItemIndex! ~/ itemsPerRow;
    final col = controller.selectedItemIndex! % itemsPerRow;

    final x = padding + col * (itemSize + spacing) + itemSize / 2;
    final y = padding + 45 + row * (itemSize + spacing) - 30;

    // 繪製提示背景
    final hintBgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - 50, y - 20, 100, 24),
      const Radius.circular(12.0),
    );

    canvas.drawRRect(
      hintBgRect,
      Paint()..color = Colors.black.withOpacity(0.6 * _hintOpacity),
    );

    canvas.drawRRect(
      hintBgRect,
      Paint()
        ..color =
            item.isEquippable
                ? Colors.green.withOpacity(0.8 * _hintOpacity)
                : Colors.blue.withOpacity(0.8 * _hintOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 繪製提示文字
    UIUtils.drawText(
      canvas,
      _hintText,
      Vector2(x, y - 8),
      align: TextAlign.center,
      color: Colors.white.withOpacity(_hintOpacity),
      fontSize: 14,
      bold: true,
    );
  }

  /// 鼠標點擊事件處理
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (!controller.isVisible) return;

    // 獲取點擊的相對位置
    final localPosition = event.localPosition;
    debugPrint("【調試】背包點擊位置: $localPosition");

    // 計算點擊的物品索引
    final itemIndex = _getItemIndexAtPosition(localPosition);
    debugPrint("【調試】點擊的物品索引: $itemIndex");

    if (itemIndex != null && itemIndex < controller.inventory.items.length) {
      // 選中點擊的物品
      controller.selectItem(itemIndex);

      // 顯示提示訊息
      final item = controller.inventory.items[itemIndex];
      final itemTypeText = item.isEquippable ? "裝備" : "使用";
      game.showMessage("已選擇 ${item.name}，按 E 鍵${itemTypeText}，1-4 鍵設為熱鍵");

      // 顯示動畫提示
      _hintText = item.isEquippable ? "按 E 鍵裝備" : "按 E 鍵使用";
      _showingHint = true;
      Future.delayed(Duration(seconds: 2), () {
        _showingHint = false;
      });
    }

    // 檢查是否點擊了物品詳情底部的按鈕
    if (controller.selectedItemIndex != null) {
      final item = controller.inventory.items[controller.selectedItemIndex!];
      final detailY = size.y - 90;

      // 使用/裝備按鈕
      final useButtonRect = Rect.fromLTWH(size.x - 280, detailY + 30, 80, 30);
      if (useButtonRect.contains(localPosition.toOffset())) {
        controller.useSelectedItem();
        return;
      }

      // 熱鍵綁定按鈕
      final bindButtonRect = Rect.fromLTWH(size.x - 180, detailY + 30, 100, 30);
      if (bindButtonRect.contains(localPosition.toOffset())) {
        game.showMessage("請按 1-4 數字鍵將 ${item.name} 綁定到熱鍵欄");
        return;
      }
    }

    // 檢查是否點擊了裝備槽
    final equipSlots = controller.equipment.slots.keys.toList();
    for (int i = 0; i < equipSlots.length; i++) {
      final slot = equipSlots[i];
      final x = size.x - 200 + padding + 90; // 裝備格子的X位置
      final y = padding + 85 + i * (itemSize + spacing); // 裝備格子的Y位置

      final equipRect = Rect.fromLTWH(x, y, itemSize, itemSize);
      if (equipRect.contains(localPosition.toOffset())) {
        controller.selectedEquipSlot = slot;

        // 如果槽位有裝備，可以顯示卸下提示
        final equipItem = controller.equipment.slots[slot];
        if (equipItem != null) {
          game.showMessage("選擇了 ${equipItem.name}，按 E 鍵卸下");
        }

        return;
      }
    }
  }

  /// 獲取滑鼠懸停的裝備槽
  String? _getHoveredEquipSlot(Vector2 position) {
    final equipSlots = controller.equipment.slots.keys.toList();
    for (int i = 0; i < equipSlots.length; i++) {
      final slot = equipSlots[i];
      final x = size.x - 200 + padding + 90; // 裝備格子的X位置
      final y = padding + 85 + i * (itemSize + spacing); // 裝備格子的Y位置

      final equipRect = Rect.fromLTWH(x, y, itemSize, itemSize);
      if (equipRect.contains(position.toOffset())) {
        return slot;
      }
    }
    return null;
  }

  /// 根據位置獲取物品索引
  int? _getItemIndexAtPosition(Vector2 position) {
    final x = position.x;
    final y = position.y;

    // 確保在背包範圍內
    if (x < padding ||
        x > padding + itemsPerRow * (itemSize + spacing) ||
        y < padding + 45 ||
        y >
            padding +
                45 +
                ((controller.inventory.maxSize / itemsPerRow).ceil()) *
                    (itemSize + spacing)) {
      return null;
    }

    final col = ((x - padding) / (itemSize + spacing)).floor();
    final row = ((y - padding - 45) / (itemSize + spacing)).floor();

    if (col < 0 || col >= itemsPerRow || row < 0) return null;

    final index = row * itemsPerRow + col;
    if (index < 0 || index >= controller.inventory.maxSize) return null;

    return index;
  }

  /// 處理鍵盤事件
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!controller.isVisible) return super.onKeyEvent(event, keysPressed);

    // 添加除錯輸出
    debugPrint(
      "【調試】物品欄接收到鍵盤事件: ${event.logicalKey}, 事件類型: ${event.runtimeType}",
    );

    if (event is KeyDownEvent) {
      return controller.handleKeyEvent(event.logicalKey, true);
    } else if (event is KeyUpEvent) {
      return controller.handleKeyEvent(event.logicalKey, false);
    }

    return true;
  }

  /// 獲取槽位顯示名稱
  String _getSlotDisplayName(String slot) {
    switch (slot) {
      case 'weapon':
        return '武器';
      case 'armor':
        return '護甲';
      default:
        return slot;
    }
  }

  /// 對外方法代理到控制器
  void open() {
    if (!_isInitialized) {
      debugPrint("【警告】嘗試開啟背包，但控制器尚未初始化");
      return;
    }
    if (_controller != null) {
      _controller!.open();
    }
  }

  void close() {
    if (!_isInitialized) {
      debugPrint("【警告】嘗試關閉背包，但控制器尚未初始化");
      return;
    }
    if (_controller != null) {
      _controller!.close();
    }
  }

  void toggle() {
    try {
      if (!_isInitialized) {
        debugPrint("【警告】嘗試切換背包顯示狀態，但控制器尚未初始化");
        return;
      }

      if (_controller != null) {
        _controller!.toggle();
      } else {
        debugPrint("【警告】無法切換背包顯示狀態：控制器為空");
      }
    } catch (e) {
      debugPrint("【錯誤】切換背包顯示狀態失敗: $e");
    }
  }

  /// 公開給外部調用的熱鍵綁定方法
  bool bindSelectedItemToHotkey(int hotkeySlot) =>
      controller.bindSelectedItemToHotkey(hotkeySlot);
}
