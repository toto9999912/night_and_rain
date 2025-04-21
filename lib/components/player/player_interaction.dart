import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../npc.dart';
import '../../ui/dialogue_system.dart';

/// 自訂可見性文字元件
class VisibleTextComponent extends TextComponent with HasVisibility {
  VisibleTextComponent({
    required String super.text,
    required TextPaint super.textRenderer,
    required Vector2 super.position,
    required Anchor super.anchor,
    super.priority,
  });
}

/// 專門處理玩家與NPC互動的類別
class PlayerInteraction {
  // NPC互動系統
  NPC? interactingNPC;
  bool canInteract = false;
  TextComponent? dialogueBox;
  final double interactionRadius;

  // 參考遊戲主類和對話系統
  final HasGameReference<NightAndRainGame> gameRef;
  final PositionComponent component;
  DialogueSystem dialogueSystem; // 移除 final 關鍵字，使其可變

  PlayerInteraction({
    required this.gameRef,
    required this.component,
    required this.dialogueSystem,
    this.interactionRadius = 60.0,
  });

  /// 設置對話框
  void setupDialogueBox() {
    // 先前簡單的對話框現在由 DialogueSystem 取代，
    // 但仍保留該方法和基本對話框以兼容舊程式碼
    dialogueBox = VisibleTextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16.0,
          color: Colors.white,
          backgroundColor: Color(0x99000000),
        ),
      ),
      position: Vector2(0, -70),
      anchor: Anchor.bottomCenter,
    )..priority = 10;

    component.add(dialogueBox!);
    (dialogueBox as HasVisibility).isVisible = false;
  }

  /// 檢查NPC互動
  void checkNPCInteractions(Vector2 playerPosition) {
    // 定義不同的互動距離
    final greetingRadius = interactionRadius * 1.2; // 問候半徑比互動半徑大
    final actionRadius = interactionRadius * 0.7; // 交談半徑比互動半徑小

    // 更新所有NPC的互動提示狀態
    for (final npc in gameRef.game.gameWorld.npcs) {
      final distance = playerPosition.distanceTo(npc.position);

      // 如果玩家在問候半徑內，顯示問候語
      if (distance <= greetingRadius) {
        npc.setGreetingVisible(true);

        // 如果玩家在交互半徑內，顯示交互提示
        if (distance <= interactionRadius) {
          npc.setInteractionHintVisible(true);

          // 如果玩家在行動半徑內，允許互動
          if (distance <= actionRadius && interactingNPC == null) {
            canInteract = true;
          }
        } else {
          npc.setInteractionHintVisible(false);
        }
      } else {
        // 如果玩家走遠，隱藏所有提示
        npc.setGreetingVisible(false);
        npc.setInteractionHintVisible(false);
      }
    }

    // 如果玩家走遠了，關閉對話
    if (interactingNPC != null) {
      final distance = playerPosition.distanceTo(interactingNPC!.position);
      if (distance > interactionRadius * 1.5) {
        hideDialogue();
        dialogueSystem.closeDialogue();
        interactingNPC = null;
      }
    }
  }

  /// 嘗試互動
  void attemptInteraction(Vector2 playerPosition) {
    if (interactingNPC != null) {
      hideDialogue();
      dialogueSystem.closeDialogue();
      interactingNPC = null;
    } else {
      interactingNPC = gameRef.game.gameWorld.interactWithNearestNPC(
        playerPosition,
        maxDistance: interactionRadius,
      );

      if (interactingNPC != null) {
        // 使用新的對話系統
        final dialogueText = interactingNPC!.getRandomDialogue();

        // 創建對話數據
        final dialogue = DialogueData(
          id:
              'npc_${interactingNPC!.id}_${DateTime.now().millisecondsSinceEpoch}',
          speaker: interactingNPC!.name,
          text: dialogueText,
          options: [
            DialogueOption(
              text: '再見',
              onSelected: () {
                hideDialogue();
                interactingNPC = null;
              },
            ),
            DialogueOption(
              text: '詢問更多',
              onSelected: () {
                final moreText = interactingNPC!.getRandomDialogue();
                showDialogue(moreText); // 使用舊的對話系統顯示更多對話
              },
            ),
          ],
        );

        // 顯示對話
        dialogueSystem.startDialogue(dialogue);

        // 同時兼容舊系統
        showDialogue(dialogueText);
      }
    }
  }

  void showDialogue(String text) {
    if (dialogueBox != null) {
      dialogueBox!.text = text;
      (dialogueBox as HasVisibility).isVisible = true;
    }
  }

  void hideDialogue() {
    if (dialogueBox != null) {
      (dialogueBox as HasVisibility).isVisible = false;
    }
  }
}
