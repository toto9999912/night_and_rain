import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../player.dart';

/// 角色狀態面板
class CharacterPanel extends PositionComponent
    with KeyboardHandler, HasGameReference<NightAndRainGame> {
  bool isVisible = false;

  // UI設定
  final double padding = 15.0;
  final double lineHeight = 25.0;
  final Color bgColor = const Color(0xDD222222);
  final Color borderColor = const Color(0xFFDDDDDD);
  final Color textColor = Colors.white;
  final Color titleColor = Colors.yellow;
  final Color valueColor = Colors.cyan;

  CharacterPanel() : super(priority: 100);

  @override
  Future<void> onLoad() async {
    size = Vector2(350, 450);
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

    // 取得玩家參考
    final Player player = game.player;

    // 繪製面板背景
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final bgPaint =
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.fill;
    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // 圓角面板
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      borderPaint,
    );

    // 繪製面板標題
    _drawText(
      canvas,
      '角色狀態',
      Vector2(size.x / 2, padding),
      TextAlign.center,
      titleColor,
      fontSize: 22,
      bold: true,
    );

    // 繪製角色基礎資訊區域
    double y = padding * 3;

    _drawText(
      canvas,
      '基本資訊',
      Vector2(padding, y),
      TextAlign.left,
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
      y,
    );
    y += lineHeight;

    // 魔力值
    _drawStatLine(
      canvas,
      '魔力值',
      '${player.currentMana.toInt()}/${player.maxMana.toInt()}',
      y,
    );
    y += lineHeight;

    // 攻擊力
    _drawStatLine(canvas, '攻擊力', player.attack.toStringAsFixed(1), y);
    y += lineHeight;

    // 防禦力
    _drawStatLine(canvas, '防禦力', player.defense.toStringAsFixed(1), y);
    y += lineHeight;

    // 速度
    _drawStatLine(canvas, '速度', player.speed.toStringAsFixed(1), y);
    y += lineHeight;

    // 等級和經驗
    _drawStatLine(canvas, '等級', '${player.level}', y);
    y += lineHeight;

    _drawStatLine(
      canvas,
      '經驗值',
      '${player.experience}/${player.experienceToNextLevel}',
      y,
    );
    y += lineHeight * 1.5;

    // 繪製裝備加成區域
    _drawText(
      canvas,
      '裝備加成',
      Vector2(padding, y),
      TextAlign.left,
      titleColor,
      fontSize: 18,
      bold: true,
    );

    y += lineHeight * 1.5;

    // 獲取所有裝備的總加成
    final equipStats = player.equipment.getTotalStats();

    // 攻擊加成
    final attackBonus = equipStats['attack'] ?? 0;
    if (attackBonus != 0) {
      _drawStatLine(
        canvas,
        '攻擊加成',
        (attackBonus > 0 ? '+' : '') + attackBonus.toStringAsFixed(1),
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
        y,
        valueColor: manaBonus > 0 ? Colors.green : Colors.red,
      );
      y += lineHeight;
    }

    // 繪製關閉提示
    _drawText(
      canvas,
      '按 C 鍵關閉面板',
      Vector2(size.x - padding, size.y - padding),
      TextAlign.right,
      Colors.yellow,
      fontSize: 14,
    );
  }

  /// 繪製屬性行
  void _drawStatLine(
    Canvas canvas,
    String label,
    String value,
    double y, {
    Color? valueColor,
  }) {
    // 繪製屬性名稱
    _drawText(
      canvas,
      '$label:',
      Vector2(padding * 2, y),
      TextAlign.left,
      textColor,
      fontSize: 16,
    );

    // 繪製屬性值
    _drawText(
      canvas,
      value,
      Vector2(size.x - padding * 2, y),
      TextAlign.right,
      valueColor ?? this.valueColor,
      fontSize: 16,
      bold: true,
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

    textPainter.paint(canvas, Offset(x, position.y));
  }

  /// 處理鍵盤事件
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      if (isVisible) {
        close();
      } else {
        open();
      }
      return true;
    }

    return false;
  }

  /// 打開角色面板
  void open() {
    isVisible = true;
  }

  /// 關閉角色面板
  void close() {
    isVisible = false;
  }

  /// 切換面板開關狀態
  void toggle() {
    isVisible ? close() : open();
  }
}
