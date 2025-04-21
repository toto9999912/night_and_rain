import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 提供共用 UI 繪製功能的工具類
class UIUtils {
  /// 繪製文字到 Canvas 上
  static void drawText(
    Canvas canvas,
    String text,
    Vector2 position, {
    TextAlign align = TextAlign.center,
    double fontSize = 16,
    bool bold = false,
    Color color = Colors.white,
    double? maxWidth,
  }) {
    final textStyle = TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontFamily: 'Cubic11');

    final textSpan = TextSpan(text: text, style: textStyle);

    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr, textAlign: align);

    textPainter.layout(maxWidth: maxWidth ?? double.infinity);

    final offset = Offset(
      align == TextAlign.center
          ? position.x - textPainter.width / 2
          : align == TextAlign.right
          ? position.x - textPainter.width
          : position.x,
      position.y,
    );

    textPainter.paint(canvas, offset);
  }

  /// 繪製進度條到 Canvas 上
  static void drawBar(Canvas canvas, Rect rect, double fillRatio, Color fillColor, {Color? bgColor, Color? borderColor}) {
    // 繪製背景
    if (bgColor != null) {
      canvas.drawRect(rect, Paint()..color = bgColor);
    }

    // 繪製填充部分
    final fillWidth = rect.width * fillRatio.clamp(0.0, 1.0);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, fillWidth, rect.height), Paint()..color = fillColor);

    // 繪製邊框
    if (borderColor != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }
}
