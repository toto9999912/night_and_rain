import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

/// 專責處理遊戲輸入的管理器
class InputManager {
  final NightAndRainGame game;

  InputManager(this.game);

  /// 處理鍵盤輸入事件
  KeyEventResult handleKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // 如果背包或角色面板開啟，且按下的是數字鍵1-4，則優先處理物品綁定
    if (game.player.inventory.isUIVisible && event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1 ||
          event.logicalKey == LogicalKeyboardKey.digit2 ||
          event.logicalKey == LogicalKeyboardKey.digit3 ||
          event.logicalKey == LogicalKeyboardKey.digit4) {
        print("【調試】輸入管理器接收到數字鍵: ${event.logicalKey}，將轉發給背包UI處理");

        // 直接獲取背包UI實例並轉發事件
        final inventoryUI = game.player.inventory.inventoryUI;
        if (inventoryUI.controller.isBindingHotkey) {
          final keyNumber =
              event.logicalKey == LogicalKeyboardKey.digit1
                  ? 1
                  : event.logicalKey == LogicalKeyboardKey.digit2
                  ? 2
                  : event.logicalKey == LogicalKeyboardKey.digit3
                  ? 3
                  : 4;

          final hotkeySlot = keyNumber - 1;
          print("【調試】直接綁定物品到熱鍵槽 $hotkeySlot");

          if (inventoryUI.controller.bindingItemIndex != null) {
            inventoryUI.bindSelectedItemToHotkey(hotkeySlot);
          }
          return KeyEventResult.handled;
        }
      }
    }

    // 處理「i」鍵打開/關閉背包
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      game.player.toggleInventory();
      return KeyEventResult.handled;
    }

    // 處理「c」鍵打開/關閉角色面板
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      game.player.toggleCharacterPanel();
      return KeyEventResult.handled;
    }

    // 處理數字鍵 1-4 快捷鍵
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        game.hotkeysHud.useHotkey(0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        game.hotkeysHud.useHotkey(1);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
        game.hotkeysHud.useHotkey(2);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
        game.hotkeysHud.useHotkey(3);
        return KeyEventResult.handled;
      }
    }

    // 只有當背包、角色面板和對話系統未打開時才處理移動和射擊
    if (!game.player.inventory.isUIVisible) {
      game.player.updateMovement(keysPressed);

      // 空格鍵射擊
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
        game.player.shoot();
      } else if (event is KeyUpEvent && event.logicalKey == LogicalKeyboardKey.space) {
        game.player.stopShooting();
      }
    } else {
      // 如果UI打開中，則停止角色移動和射擊
      game.player.movement.stopMovement();
      game.player.stopShooting();
    }

    return KeyEventResult.handled;
  }

  /// 處理滑鼠移動
  void handleMouseMove(PointerHoverInfo info) {
    game.mousePosition = game.cameraComponent.globalToLocal(info.eventPosition.global);
    game.player.updateWeaponAngle(game.mousePosition);
  }

  /// 處理點擊開始
  void handleTapDown(TapDownInfo info) {
    game.mousePosition = game.cameraComponent.globalToLocal(info.eventPosition.global);
    game.player.updateWeaponAngle(game.mousePosition);
    game.player.shoot();
  }

  /// 處理點擊結束
  void handleTapUp(TapUpInfo info) {
    game.player.stopShooting();
  }
}
