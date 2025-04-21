import 'package:flame/components.dart';

import 'package:flutter/material.dart';
import 'package:night_and_rain/main.dart';

import '../player.dart';

/// HUD Component：顯示血條與魔力條
class HealthManaHud extends PositionComponent
    with HasGameReference<NightAndRainGame> {
  // 條寬、高與間距設定
  static const double barWidth = 150.0;
  static const double barHeight = 15.0;
  static const double spacing = 5.0;

  // 玩家引用
  final Player player;

  // 畫筆
  final Paint _bgPaint = Paint()..color = const Color(0xFF333333);
  final Paint _hpPaint = Paint()..color = Colors.green;
  final Paint _spPaint = Paint()..color = Colors.blue;

  HealthManaHud({required this.player}) {
    // 設定在畫布左上角
    position = Vector2(10, 10);
    // 高度：兩條加間距
    size = Vector2(barWidth, barHeight * 2 + spacing);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final hpRatio = player.currentHealth / player.maxHealth;
    final spRatio = player.currentMana / player.maxMana;

    // 1. 血條背景
    final bgHp = Rect.fromLTWH(0, 0, barWidth, barHeight);
    canvas.drawRect(bgHp, _bgPaint);
    // 2. 血條前景
    final fgHp = Rect.fromLTWH(0, 0, barWidth * hpRatio, barHeight);
    _hpPaint.color = _getHealthColor(hpRatio);
    canvas.drawRect(fgHp, _hpPaint);
    // 3. 血條文字
    _drawText(
      canvas,
      '${player.currentHealth.toInt()}/${player.maxHealth.toInt()}',
      // 文字置中
      Offset(barWidth / 2, barHeight / 2),
    );

    // 4. 魔力條背景
    final ySp = barHeight + spacing;
    final bgSp = Rect.fromLTWH(0, ySp, barWidth, barHeight);
    canvas.drawRect(bgSp, _bgPaint);
    // 5. 魔力條前景
    final fgSp = Rect.fromLTWH(0, ySp, barWidth * spRatio, barHeight);
    canvas.drawRect(fgSp, _spPaint);
    // 6. 魔力條文字
    _drawText(
      canvas,
      '${player.currentMana.toInt()}/${player.maxMana.toInt()}',
      Offset(barWidth / 2, ySp + barHeight / 2),
    );
  }

  // 畫文字到 Canvas 上
  void _drawText(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  Color _getHealthColor(double ratio) {
    if (ratio > 0.6) return Colors.green;
    if (ratio > 0.3) return Colors.orange;
    return Colors.red;
  }
}
