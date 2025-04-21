import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../components/enums/item_type.dart';
import '../components/items/inventory.dart';
import '../components/items/equipment.dart';
import '../components/items/weapon_item.dart';
import '../player.dart';
import '../utils/ui_utils.dart'; // 引入公共 UI 工具類

/// 背包 UI 的控制器類，處理業務邏輯，不包含渲染邏輯
class InventoryUIController {
  final NightAndRainGame game;
  final Inventory inventory;
  final Equipment equipment;

  // UI 狀態 (仍需在控制器中保存，但只限業務邏輯相關的狀態)
  bool isVisible = false;
  int? selectedItemIndex;
  String? selectedEquipSlot;

  // 熱鍵綁定相關狀態
  bool isBindingHotkey = false;
  int? bindingItemIndex;

  InventoryUIController({
    required this.game,
    required this.inventory,
    required this.equipment,
  });

  /// 選擇背包中的物品
  void selectItem(int? index) {
    selectedItemIndex = index;
    // 如果選中了新物品，重置綁定狀態
    if (index != null &&
        (bindingItemIndex == null || bindingItemIndex != index)) {
      isBindingHotkey = false;
      bindingItemIndex = null;
      print("【調試】選中新物品，索引: $selectedItemIndex");
    }
  }

  /// 嘗試綁定熱鍵
  void toggleBindingMode(int index) {
    // 如果點擊已選中的物品，則啟動熱鍵綁定模式
    if (index == selectedItemIndex) {
      // 切換到熱鍵綁定模式
      isBindingHotkey = true;
      bindingItemIndex = index;
      print("【調試】啟動熱鍵綁定模式，物品索引: $bindingItemIndex");
      _showMessage("請按下 1-4 數字鍵將此物品綁定到熱鍵欄");
    } else {
      // 選中新物品
      selectedItemIndex = index;
      // 重置綁定狀態
      isBindingHotkey = false;
      bindingItemIndex = null;
    }
  }

  /// 將選中的物品綁定到指定熱鍵槽位
  bool bindSelectedItemToHotkey(int hotkeySlot) {
    if (selectedItemIndex == null ||
        selectedItemIndex! >= inventory.items.length) {
      print("【調試】綁定失敗：無效的物品索引 $selectedItemIndex");
      return false;
    }

    final item = inventory.items[selectedItemIndex!];
    print("【調試】嘗試綁定物品: ${item.name}，類型: ${item.type}，到熱鍵槽: $hotkeySlot");

    // 獲取HotkeysHud實例
    final hotkeysHud = game.hotkeysHud;
    if (hotkeysHud == null) {
      print("【調試】錯誤: hotkeysHud為空");
      return false;
    }

    if (item.type == ItemType.weapon) {
      // 如果是武器物品，檢查玩家是否擁有此武器
      final weaponItem = item as WeaponItem;
      print("【調試】武器類型: ${weaponItem.weapon.runtimeType}");
      print(
        "【調試】玩家擁有的武器: ${game.player.weapons.map((w) => w.runtimeType).toList()}",
      );

      final weaponIndex = game.player.weapons.indexWhere(
        (w) => w.runtimeType == weaponItem.weapon.runtimeType,
      );
      print("【調試】找到武器索引: $weaponIndex");

      if (weaponIndex >= 0) {
        // 玩家已有此武器，綁定到熱鍵
        print(
          "【調試】綁定武器 ${game.player.weapons[weaponIndex].name} 到熱鍵槽 $hotkeySlot",
        );
        hotkeysHud.setWeaponHotkey(
          hotkeySlot,
          game.player.weapons[weaponIndex],
          weaponIndex,
        );
        _showBindSuccessMessage(item.name, hotkeySlot);
        return true;
      } else {
        // 玩家尚未擁有此武器，無法綁定
        print("【調試】無法綁定: 玩家未擁有此武器");
        _showMessage("必須先裝備此武器才能添加到熱鍵");
        return false;
      }
    } else {
      // 如果是消耗品或其他類型物品，直接添加到熱鍵
      print("【調試】綁定消耗品 ${item.name} 到熱鍵槽 $hotkeySlot");
      hotkeysHud.setConsumableHotkey(hotkeySlot, item);
      _showBindSuccessMessage(item.name, hotkeySlot);
      return true;
    }
  }

  /// 處理背包內物品的使用
  void useSelectedItem() {
    if (selectedItemIndex != null &&
        selectedItemIndex! < inventory.items.length) {
      inventory.useItem(selectedItemIndex!);
    }
  }

  /// 處理鍵盤事件，返回是否已處理
  bool handleKeyEvent(LogicalKeyboardKey key, bool isKeyDown) {
    if (!isVisible) return false;

    if (isKeyDown) {
      final keyNumber = _getNumberFromKey(key);

      // 如果正在綁定模式且按下了1-4數字鍵
      if (isBindingHotkey &&
          bindingItemIndex != null &&
          bindingItemIndex! < inventory.items.length &&
          keyNumber != null &&
          keyNumber >= 1 &&
          keyNumber <= 4) {
        final hotkeySlot = keyNumber - 1;
        if (bindSelectedItemToHotkey(hotkeySlot)) {
          // 綁定後關閉綁定模式
          isBindingHotkey = false;
          bindingItemIndex = null;
        }
        return true;
      }
      // 如果已選中物品並且按下了1-4數字鍵 (非綁定模式)
      else if (selectedItemIndex != null &&
          selectedItemIndex! < inventory.items.length &&
          keyNumber != null &&
          keyNumber >= 1 &&
          keyNumber <= 4) {
        final hotkeySlot = keyNumber - 1; // 轉換為0-3的索引
        if (bindSelectedItemToHotkey(hotkeySlot)) {
          // 綁定後關閉綁定模式
          isBindingHotkey = false;
          bindingItemIndex = null;
        }
        return true;
      }

      // 一般模式 - 使用數字鍵1-9快速使用物品
      if (keyNumber != null &&
          keyNumber > 0 &&
          keyNumber <= inventory.items.length) {
        print("【調試】使用物品索引: ${keyNumber - 1}");
        inventory.useItem(keyNumber - 1);
        return true;
      }
    }

    return true;
  }

  /// 顯示成功綁定的消息
  void _showBindSuccessMessage(String itemName, int hotkeySlot) {
    _showMessage("已將 $itemName 綁定至熱鍵 ${hotkeySlot + 1}");
  }

  /// 顯示消息
  void _showMessage(String message) {
    game.showMessage(message);
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
    isBindingHotkey = false;
    bindingItemIndex = null;
  }

  /// 切換背包開關狀態
  void toggle() {
    isVisible ? close() : open();
  }
}

/// 背包 UI 視圖類，只處理渲染和使用者輸入，不包含業務邏輯
class InventoryUI extends PositionComponent
    with TapCallbacks, KeyboardHandler, HasGameReference<NightAndRainGame> {
  // 視圖設置和狀態
  final double padding = 10.0;
  final double itemSize = 60.0;
  final double spacing = 5.0;
  final int itemsPerRow = 5;

  // 懸停元素視圖狀態（僅UI相關，不影響邏輯）
  int? hoveredItemIndex;
  String? hoveredEquipSlot;

  // 角色面板相關設置
  final double lineHeight = 25.0;
  final Color titleColor = Colors.yellow;
  final Color valueColor = Colors.cyan;

  // 控制器 - 使用可空類型，並添加一個安全的 getter
  InventoryUIController? _controller;
  InventoryUIController get controller {
    if (_controller == null) {
      if (!_isInitialized || game == null) {
        print("【警告】組件尚未完全初始化，無法安全地創建控制器");
        throw Exception("嘗試訪問未初始化的控制器：組件尚未附加到遊戲實例或尚未完成初始化");
      }

      try {
        print("初始化庫存UI控制器");
        _controller = InventoryUIController(
          game: game,
          inventory: _inventory,
          equipment: _equipment,
        );
      } catch (e) {
        print("【嚴重錯誤】無法創建控制器: $e");
        throw Exception("無法創建庫存UI控制器: $e");
      }
    }
    return _controller!;
  }

  // 存儲構造函數傳入的參數，以便在 onLoad 中初始化控制器
  final Inventory _inventory;
  final Equipment _equipment;

  // 標示是否已初始化
  bool _isInitialized = false;

  InventoryUI({required Inventory inventory, required Equipment equipment})
    : _inventory = inventory,
      _equipment = equipment,
      super(priority: 100);

  @override
  Future<void> onLoad() async {
    try {
      // 在 onLoad 中初始化控制器，此時 game 應該已經可用
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

      // 為每個物品加載對應的圖標
      for (final item in _inventory.items) {
        item.sprite = spriteSheet.getSprite(item.spriteX, item.spriteY);
      }

      // 為裝備中的物品也加載圖標
      for (final equipSlot in _equipment.slots.keys) {
        final item = _equipment.slots[equipSlot];
        if (item != null && item.sprite == null) {
          item.sprite = spriteSheet.getSprite(item.spriteX, item.spriteY);
        }
      }

      // 設置背包UI的大小和位置 - 考慮裝備區域和角色狀態面板
      size = Vector2(
        itemsPerRow * (itemSize + spacing) + padding * 2 + 400, // 增加右側區域寬度
        ((controller.inventory.maxSize / itemsPerRow).ceil()) *
                (itemSize + spacing) +
            padding * 2 +
            50, // 增加高度以適應角色狀態
      );

      // 居中顯示
      position = Vector2(
        game.size.x / 2 - size.x / 2,
        game.size.y / 2 - size.y / 2,
      );
    } catch (e) {
      print("【錯誤】初始化 InventoryUI 失敗: $e");
    }

    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 如果背包不可見，則不渲染
    if (!controller.isVisible) return;

    // 繪製背景和邊框
    _drawBackground(canvas);

    // 繪製標題
    UIUtils.drawText(
      canvas,
      '背包與角色狀態',
      Vector2(size.x / 2, padding),
      align: TextAlign.center,
      color: Colors.white,
      fontSize: 18,
    );

    // 繪製物品格子
    _drawItemSlots(canvas);

    // 繪製裝備區域
    _drawEquipmentSlots(canvas);

    // 繪製選中物品的詳細說明
    _drawItemDetails(canvas);

    // 繪製角色狀態面板
    _drawCharacterStats(canvas);
  }

  /// 繪製背景和邊框
  void _drawBackground(Canvas canvas) {
    // 繪製背包背景
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    UIUtils.drawRect(
      canvas,
      bgRect,
      const Color(0xDD333333),
      borderColor: Colors.grey,
      borderWidth: 2.0,
    );
  }

  /// 繪製物品格子
  void _drawItemSlots(Canvas canvas) {
    for (int i = 0; i < controller.inventory.maxSize; i++) {
      final row = i ~/ itemsPerRow;
      final col = i % itemsPerRow;

      final x = padding + col * (itemSize + spacing);
      final y = padding + 30 + row * (itemSize + spacing); // 30 為標題高度

      // 繪製格子
      final slotRect = Rect.fromLTWH(x, y, itemSize, itemSize);
      UIUtils.drawRect(
        canvas,
        slotRect,
        i == controller.selectedItemIndex
            ? const Color(0xFF555555)
            : const Color(0xFF444444),
        borderColor:
            i == hoveredItemIndex ? Colors.yellow : Colors.grey.shade600,
        borderWidth: 1.0,
      );

      // 如果格子有物品，則繪製物品
      if (i < controller.inventory.items.length) {
        final item = controller.inventory.items[i];

        // 繪製物品圖示
        item.sprite?.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2(itemSize, itemSize),
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
          UIUtils.drawText(
            canvas,
            item.quantity.toString(),
            Vector2(x + itemSize - 5, y + 15),
            align: TextAlign.right,
            color: Colors.white,
            fontSize: 14,
            bold: true,
          );
        }
      }
    }
  }

  /// 繪製裝備區域
  void _drawEquipmentSlots(Canvas canvas) {
    final equipSlots = controller.equipment.slots.keys.toList();
    for (int i = 0; i < equipSlots.length; i++) {
      final slot = equipSlots[i];
      final x = size.x - 200 + padding; // 裝備區域的X位置
      final y = padding + 30 + i * (itemSize + spacing); // 裝備區域的Y位置

      // 繪製裝備格子
      final slotRect = Rect.fromLTWH(x, y, itemSize, itemSize);
      UIUtils.drawRect(
        canvas,
        slotRect,
        slot == controller.selectedEquipSlot
            ? const Color(0xFF555555)
            : const Color(0xFF444444),
        borderColor:
            slot == hoveredEquipSlot ? Colors.yellow : Colors.grey.shade600,
        borderWidth: 1.0,
      );

      // 如果格子有裝備，則繪製裝備
      final equipItem = controller.equipment.slots[slot];
      if (equipItem != null) {
        // 繪製裝備圖示
        equipItem.sprite?.render(
          canvas,
          position: Vector2(x, y),
          size: Vector2(itemSize, itemSize),
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
      }
    }
  }

  /// 繪製選中物品的詳細信息
  void _drawItemDetails(Canvas canvas) {
    if (controller.selectedItemIndex == null ||
        controller.selectedItemIndex! >= controller.inventory.items.length) {
      return;
    }

    final item = controller.inventory.items[controller.selectedItemIndex!];
    final detailX = padding;
    final detailY = size.y - 80; // 底部留出空間顯示詳情

    // 繪製詳情背景
    final detailRect = Rect.fromLTWH(
      detailX,
      detailY,
      size.x - padding * 2,
      70,
    );
    UIUtils.drawRect(canvas, detailRect, const Color(0xFF222222));

    // 繪製物品名稱
    UIUtils.drawText(
      canvas,
      item.name,
      Vector2(detailX + 10, detailY + 15),
      align: TextAlign.left,
      color: item.rarityColor,
      fontSize: 16,
      bold: true,
    );

    // 繪製物品描述
    UIUtils.drawText(
      canvas,
      item.description,
      Vector2(detailX + 10, detailY + 35),
      align: TextAlign.left,
      color: Colors.white,
      fontSize: 12,
    );

    // 繪製使用提示
    UIUtils.drawText(
      canvas,
      '點擊物品使用',
      Vector2(detailX + 10, detailY + 55),
      align: TextAlign.left,
      color: Colors.yellow,
      fontSize: 12,
    );

    // 繪製熱鍵綁定提示
    UIUtils.drawText(
      canvas,
      '按下數字鍵 1-4 綁定至熱鍵欄',
      Vector2(size.x - padding - 10, detailY + 55),
      align: TextAlign.right,
      color: Colors.cyan,
      fontSize: 12,
    );

    // 如果正在綁定熱鍵，顯示提示
    if (controller.isBindingHotkey &&
        controller.bindingItemIndex == controller.selectedItemIndex) {
      UIUtils.drawText(
        canvas,
        '請按下 1-4 數字鍵選擇熱鍵位置',
        Vector2(size.x / 2, detailY - 10),
        align: TextAlign.center,
        color: Colors.yellow,
        fontSize: 16,
        bold: true,
      );
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
    UIUtils.drawText(
      canvas,
      '角色狀態',
      Vector2(statsX + 80, padding * 2),
      align: TextAlign.center,
      color: titleColor,
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
    UIUtils.drawText(
      canvas,
      '裝備加成',
      Vector2(statsX, y),
      align: TextAlign.left,
      color: titleColor,
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
    UIUtils.drawText(
      canvas,
      '$label:',
      Vector2(x, y),
      align: TextAlign.left,
      color: Colors.white,
      fontSize: 14,
    );

    // 繪製屬性值
    UIUtils.drawText(
      canvas,
      value,
      Vector2(x + 160, y),
      align: TextAlign.right,
      color: valueColor ?? this.valueColor,
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
    print("【調試】背包點擊位置: $localPosition");

    // 計算點擊的物品索引
    final itemIndex = _getItemIndexAtPosition(localPosition);
    print("【調試】點擊的物品索引: $itemIndex");

    if (itemIndex != null && itemIndex < controller.inventory.items.length) {
      print("【調試】點擊的物品: ${controller.inventory.items[itemIndex].name}");

      controller.toggleBindingMode(itemIndex);
    }
  }

  /// 鼠標移動事件處理
  void onPointerMove(Vector2 position) {
    if (!controller.isVisible) return;

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
    if (index < 0 || index >= controller.inventory.maxSize) return null;

    return index;
  }

  /// 處理鍵盤事件
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!controller.isVisible) return super.onKeyEvent(event, keysPressed);

    // 添加除錯輸出
    print("【調試】物品欄接收到鍵盤事件: ${event.logicalKey}, 事件類型: ${event.runtimeType}");

    if (event is KeyDownEvent) {
      return controller.handleKeyEvent(event.logicalKey, true);
    } else if (event is KeyUpEvent) {
      return controller.handleKeyEvent(event.logicalKey, false);
    }

    return true;
  }

  /// 對外方法代理到控制器
  void open() {
    if (!_isInitialized) {
      print("【警告】嘗試開啟背包，但控制器尚未初始化");
      return;
    }
    if (_controller != null) {
      _controller!.open();
    }
  }

  void close() {
    if (!_isInitialized) {
      print("【警告】嘗試關閉背包，但控制器尚未初始化");
      return;
    }
    if (_controller != null) {
      _controller!.close();
    }
  }

  void toggle() {
    try {
      if (!_isInitialized) {
        print("【警告】嘗試切換背包顯示狀態，但控制器尚未初始化");
        return;
      }

      if (_controller != null) {
        _controller!.toggle();
      } else {
        print("【警告】無法切換背包顯示狀態：控制器為空");
      }
    } catch (e) {
      print("【錯誤】切換背包顯示狀態失敗: $e");
    }
  }

  /// 公開給外部調用的熱鍵綁定方法
  bool bindSelectedItemToHotkey(int hotkeySlot) =>
      controller.bindSelectedItemToHotkey(hotkeySlot);
}
