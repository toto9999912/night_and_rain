import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

/// 對話選項類型
class DialogueOption {
  final String text;
  final String? nextDialogueId;
  final Function? onSelected;

  DialogueOption({required this.text, this.nextDialogueId, this.onSelected});
}

/// 對話數據類型
class DialogueData {
  final String id;
  final String speaker;
  final String text;
  final List<DialogueOption> options;
  final String? portraitPath;

  DialogueData({
    required this.id,
    required this.speaker,
    required this.text,
    this.options = const [],
    this.portraitPath,
  });
}

/// 對話系統UI組件
class DialogueSystem extends PositionComponent
    with KeyboardHandler, HasGameReference<NightAndRainGame> {
  bool isVisible = false;
  DialogueData? currentDialogue;
  int currentTextIndex = 0;
  String displayedText = '';
  bool isTyping = false;
  int selectedOptionIndex = 0;

  // 打字動畫設定
  final double typingSpeed = 0.05; // 每個字顯示的時間間隔(秒)
  double typingTimer = 0;

  // UI設定
  final double padding = 15.0;
  final double portraitSize = 100.0;
  final double textSpeed = 30.0; // 每秒顯示的字元數

  DialogueSystem() : super(priority: 100);

  @override
  Future<void> onLoad() async {
    size = Vector2(game.size.x * 0.9, game.size.y * 0.25);
    position = Vector2(game.size.x / 2 - size.x / 2, game.size.y - size.y - 20);
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 如果對話框不可見或無對話數據，則返回
    if (!isVisible || currentDialogue == null) return;

    // 處理打字動畫效果
    if (isTyping) {
      typingTimer += dt;
      int newLength = (typingTimer * textSpeed).floor();

      if (newLength < currentDialogue!.text.length) {
        displayedText = currentDialogue!.text.substring(0, newLength);
      } else {
        displayedText = currentDialogue!.text;
        isTyping = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!isVisible || currentDialogue == null) return;

    // 繪製對話框背景
    final bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final bgPaint =
        Paint()
          ..color = const Color(0xDD222222)
          ..style = PaintingStyle.fill;
    final borderPaint =
        Paint()
          ..color = const Color(0xFFDDDDDD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // 圓角對話框
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      borderPaint,
    );

    // 繪製頭像區域
    double textStartX = padding;

    if (currentDialogue!.portraitPath != null) {
      final portraitRect = Rect.fromLTWH(
        padding,
        padding,
        portraitSize,
        portraitSize,
      );
      canvas.drawRect(portraitRect, Paint()..color = Colors.grey.shade800);
      canvas.drawRect(
        portraitRect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // 這裡可以繪製頭像圖片
      // 如果使用Sprite，需要在這裡添加繪製sprite的代碼

      textStartX = padding * 2 + portraitSize;
    }

    // 繪製說話者名稱
    _drawText(
      canvas,
      currentDialogue!.speaker,
      Vector2(textStartX, padding * 2),
      TextAlign.left,
      Colors.yellow,
      fontSize: 18,
      bold: true,
    );

    // 繪製對話文本
    _drawText(
      canvas,
      displayedText,
      Vector2(textStartX, padding * 4),
      TextAlign.left,
      Colors.white,
      fontSize: 16,
      maxWidth: size.x - textStartX - padding,
      maxLines: 4,
    );

    // 繪製對話選項
    if (!isTyping && currentDialogue!.options.isNotEmpty) {
      final optionsStartY =
          size.y - padding - (currentDialogue!.options.length * 25.0);

      for (int i = 0; i < currentDialogue!.options.length; i++) {
        final option = currentDialogue!.options[i];
        final isSelected = i == selectedOptionIndex;

        _drawText(
          canvas,
          isSelected ? '> ${option.text}' : '  ${option.text}',
          Vector2(textStartX, optionsStartY + i * 25),
          TextAlign.left,
          isSelected ? Colors.yellow : Colors.white,
          fontSize: 16,
          bold: isSelected,
        );
      }
    } else if (!isTyping) {
      // 繪製繼續提示
      _drawText(
        canvas,
        '按空白鍵繼續...',
        Vector2(size.x - padding, size.y - padding),
        TextAlign.right,
        Colors.yellow,
        fontSize: 14,
      );
    }
  }

  /// 開始或繼續對話
  void startDialogue(DialogueData dialogue) {
    currentDialogue = dialogue;
    displayedText = '';
    typingTimer = 0;
    isTyping = true;
    selectedOptionIndex = 0;
    isVisible = true;
  }

  /// 立即顯示所有文字(跳過動畫)
  void showAllText() {
    if (currentDialogue != null) {
      displayedText = currentDialogue!.text;
      isTyping = false;
    }
  }

  /// 進入下一段對話
  void advanceDialogue(String? nextDialogueId) {
    // 如果有指定下一段對話ID，則需要由遊戲邏輯載入該對話
    // 這裡僅關閉當前對話框，需要由外部代碼處理下一段對話的載入
    if (nextDialogueId == null) {
      closeDialogue();
    }
  }

  /// 選擇對話選項
  void selectOption(int index) {
    if (currentDialogue == null ||
        index < 0 ||
        index >= currentDialogue!.options.length) {
      return;
    }

    final option = currentDialogue!.options[index];

    // 執行選項的回調函數(如果有)
    if (option.onSelected != null) {
      option.onSelected!();
    }

    // 進入下一段對話
    advanceDialogue(option.nextDialogueId);
  }

  /// 關閉對話框
  void closeDialogue() {
    isVisible = false;
    currentDialogue = null;
  }

  /// 處理鍵盤事件
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!isVisible || currentDialogue == null) return false;

    if (event is KeyDownEvent) {
      // 空白鍵處理
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (isTyping) {
          // 如果正在打字動畫中，則跳過動畫
          showAllText();
        } else if (currentDialogue!.options.isEmpty) {
          // 如果沒有選項，則關閉對話
          closeDialogue();
        } else {
          // 如果有選項，則選擇當前選項
          selectOption(selectedOptionIndex);
        }
        return true;
      }

      // 上下鍵選擇選項
      if (!isTyping && currentDialogue!.options.isNotEmpty) {
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          selectedOptionIndex =
              (selectedOptionIndex - 1 + currentDialogue!.options.length) %
              currentDialogue!.options.length;
          return true;
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          selectedOptionIndex =
              (selectedOptionIndex + 1) % currentDialogue!.options.length;
          return true;
        }
      }
    }

    return false;
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
    double? maxWidth,
    int? maxLines,
  }) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );

    final textSpan = TextSpan(text: text, style: textStyle);

    final textPainter = TextPainter(
      text: textSpan,
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

    textPainter.paint(canvas, Offset(x, position.y));
  }
}
