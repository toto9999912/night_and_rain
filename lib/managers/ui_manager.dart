import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../ui/hotkeys_hud.dart';
import '../ui/current_weapon_hud.dart';
import '../ui/health_mana_hud.dart';
import '../main.dart';

/// 專責管理所有UI相關元素的類別
class UIManager {
  final NightAndRainGame game;
  late final Component uiLayer;
  late final HotkeysHud hotkeysHud;

  // 消息顯示相關屬性
  TextComponent? _messageComponent;
  Timer? _messageTimer;

  UIManager(this.game);

  /// 初始化UI元素
  Future<void> initialize() async {
    // 創建UI層，固定位置，不會隨著相機移動
    uiLayer = Component(priority: 100);
    game.add(uiLayer);

    // 添加健康魔法值HUD
    final healthManaHud = HealthManaHud(player: game.player);
    game.cameraComponent.viewport.add(healthManaHud);

    // 創建并添加快捷鍵 HUD
    hotkeysHud = HotkeysHud();
    debugPrint("【調試】初始化熱鍵欄: $hotkeysHud");
    game.cameraComponent.viewport.add(hotkeysHud);

    // 添加當前武器 HUD，放在 hotkeysHud 左側
    final currentWeaponHud = CurrentWeaponHud();
    game.cameraComponent.viewport.add(currentWeaponHud);
  }

  /// 顯示一條消息在螢幕上
  void showMessage(String message, {double duration = 2.0}) {
    if (_messageComponent != null) {
      _messageComponent!.removeFromParent();
      _messageComponent = null;
    }

    if (_messageTimer != null && !_messageTimer!.finished) {
      _messageTimer!.stop();
    }

    _messageComponent = TextComponent(
      text: message,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          backgroundColor: Color(0x99000000),
          fontFamily: 'Cubic11',
        ),
      ),
      anchor: Anchor.topCenter,
      position: Vector2(game.size.x / 2, 50),
    );

    game.world.add(_messageComponent!);

    _messageTimer = Timer(
      duration,
      onTick: () {
        if (_messageComponent != null) {
          _messageComponent!.removeFromParent();
          _messageComponent = null;
        }
      },
    );
  }

  /// 更新消息計時器
  void update(double dt) {
    if (_messageTimer != null && !_messageTimer!.finished) {
      _messageTimer!.update(dt);
    }
  }
}
