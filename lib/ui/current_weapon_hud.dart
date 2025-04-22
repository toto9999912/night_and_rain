import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../components/weapons/weapon.dart';
import '../components/weapons/pistol.dart';
import '../components/weapons/shotgun.dart';
import '../components/weapons/machine_gun.dart';
import '../main.dart';
import '../player.dart';
import 'hotkeys_hud.dart';

/// 當前武器 HUD 組件，顯示玩家目前使用的武器
class CurrentWeaponHud extends PositionComponent
    with HasGameReference<NightAndRainGame> {
  // 將靜態成員重命名，避免與 PositionComponent 衝突
  static const double hudWidth = 160.0;
  static const double hudHeight = 60.0;
  static const double iconSize = 44.0;

  // 玩家實例引用
  Player get player => game.player;

  // 武器和物品的精靈圖
  SpriteSheet? _spriteSheet;

  // 顯示動畫效果相關
  double _animationProgress = 0;
  bool _isAnimating = false;
  String _lastWeaponName = '';

  // 添加熱鍵索引顯示
  int? weaponHotkeyNumber;

  // 武器切換動畫相關參數
  final double _animationDuration = 0.3; // 動畫持續時間（秒）
  Weapon? _previousWeapon;

  CurrentWeaponHud() : super(priority: 10) {
    // 使用新命名的靜態常量
    size = Vector2(hudWidth, hudHeight);
  }

  @override
  Future<void> onLoad() async {
    // 設置在畫面左下角，考慮到要與 HotkeysHud 對齊
    position = Vector2(20, game.size.y - hudHeight - 20);

    // 載入物品精靈圖表
    await _loadSpriteSheet();

    await super.onLoad();
  }

  /// 載入物品精靈圖表
  Future<void> _loadSpriteSheet() async {
    try {
      final image = await Flame.images.load('item_pack.png');
      _spriteSheet = SpriteSheet(image: image, srcSize: Vector2(24, 24));
      debugPrint("當前武器 HUD 物品精靈圖載入成功");
    } catch (e) {
      debugPrint("當前武器 HUD 載入物品精靈圖失敗: $e");
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新當前武器對應的熱鍵編號
    weaponHotkeyNumber = _findWeaponHotkey();

    // 檢查武器是否已更改
    if (player.combat.weapons.isNotEmpty &&
        player.currentWeapon != null &&
        player.currentWeapon!.name != _lastWeaponName) {
      _lastWeaponName = player.currentWeapon!.name;
      _isAnimating = true;
      _animationProgress = 0;
    }

    // 檢查武器是否變化，如果變化則啟動動畫
    if (!_isAnimating && _previousWeapon != player.currentWeapon) {
      _startWeaponChangeAnimation();
    }

    // 更新武器切換動畫
    if (_isAnimating) {
      _animationProgress += dt / _animationDuration;
      if (_animationProgress >= 1.0) {
        _isAnimating = false;
        _animationProgress = 0.0;
        _previousWeapon = player.currentWeapon;
      }
    }
  }

  // 啟動武器切換動畫
  void _startWeaponChangeAnimation() {
    _isAnimating = true;
    _animationProgress = 0.0;
    _previousWeapon = game.player.currentWeapon;
  }

  // 查找當前武器的熱鍵編號
  int? _findWeaponHotkey() {
    final hotkeysHud = game.hotkeysHud;
    final currentWeaponIndex = game.player.combat.currentWeaponIndex;

    for (int i = 0; i < HotkeysHud.hotkeyCount; i++) {
      final hotkey = hotkeysHud.hotkeys[i];
      if (hotkey.type == HotkeyItemType.weapon &&
          hotkey.weaponIndex == currentWeaponIndex) {
        return i + 1; // 返回1-4的熱鍵編號
      }
    }
    return null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 繪製背景
    final bgPaint = Paint()..color = const Color(0xDD333333);
    final borderPaint =
        Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // 使用新命名的靜態常量
    final bgRect = Rect.fromLTWH(0, 0, hudWidth, hudHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      borderPaint,
    );

    // 檢查玩家是否有武器
    if (player.combat.weapons.isEmpty ||
        player.currentWeapon == null ||
        _spriteSheet == null) {
      // 顯示無武器的提示
      _drawText(
        canvas,
        "無裝備武器",
        Vector2(hudWidth / 2, hudHeight / 2 - 5),
        color: Colors.grey,
      );

      // 顯示提示訊息
      _drawText(
        canvas,
        "按 I 開啟背包綁定武器",
        Vector2(hudWidth / 2, hudHeight / 2 + 15),
        fontSize: 10,
        color: Colors.lightBlueAccent,
      );
      return;
    }

    // 獲取當前武器
    final currentWeapon = player.currentWeapon!; // 我們已經檢查了它不是 null

    // 根據武器類型獲取對應圖示
    int spriteX = 0;
    int spriteY = 0;

    if (currentWeapon is Pistol) {
      spriteX = 0;
      spriteY = 0;
    } else if (currentWeapon is Shotgun) {
      spriteX = 1;
      spriteY = 0;
    } else if (currentWeapon is MachineGun) {
      spriteX = 2;
      spriteY = 0;
    }

    // 計算動畫效果的縮放比例
    double scale = 1.0;
    if (_isAnimating) {
      // 先放大後縮小的彈性效果
      if (_animationProgress < 0.5) {
        scale = 1.0 + (_animationProgress * 0.5);
      } else {
        scale = 1.25 - ((_animationProgress - 0.5) * 0.5);
      }
    }

    // 繪製武器圖示
    final weaponSprite = _spriteSheet!.getSprite(spriteX, spriteY);
    final scaledIconSize = iconSize * scale;
    weaponSprite.render(
      canvas,
      position: Vector2(
        10 + (iconSize - scaledIconSize) / 2,
        (hudHeight - scaledIconSize) / 2,
      ),
      size: Vector2.all(scaledIconSize),
    );

    // 繪製武器名稱
    _drawText(
      canvas,
      currentWeapon.name,
      Vector2(iconSize + 20, 20),
      fontSize: 18,
      bold: true,
      color: _getWeaponRarityColor(currentWeapon.rarity),
      align: TextAlign.left,
    );

    // 繪製武器類型
    _drawText(
      canvas,
      _getWeaponTypeText(currentWeapon),
      Vector2(iconSize + 20, 40),
      fontSize: 14,
      align: TextAlign.left,
    );

    // 顯示對應的熱鍵編號(如果有)
    if (weaponHotkeyNumber != null) {
      _drawText(
        canvas,
        "[$weaponHotkeyNumber]",
        Vector2(size.x - 10, 20),
        fontSize: 18,
        bold: true,
        color: Colors.yellow,
        align: TextAlign.right,
      );
    }
  }

  /// 根據武器種類獲取類型文字
  String _getWeaponTypeText(Weapon weapon) {
    if (weapon is Pistol) return "手槍";
    if (weapon is Shotgun) return "散彈槍";
    if (weapon is MachineGun) return "機關槍";
    return "未知武器";
  }

  /// 獲取武器稀有度對應的顏色
  Color _getWeaponRarityColor(dynamic rarity) {
    if (rarity == null) return Colors.white;

    try {
      switch (rarity.toString()) {
        case 'common':
          return Colors.white;
        case 'uncommon':
          return Colors.green;
        case 'rare':
          return Colors.blue;
        case 'epic':
          return Colors.purple;
        case 'legendary':
          return Colors.orange;
        default:
          return Colors.white;
      }
    } catch (_) {
      return Colors.white;
    }
  }

  /// 文字繪製輔助方法
  void _drawText(
    Canvas canvas,
    String text,
    Vector2 position, {
    TextAlign align = TextAlign.center,
    double fontSize = 14,
    bool bold = false,
    Color color = Colors.white,
    double? maxWidth,
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

    textPainter.paint(canvas, Offset(x, position.y - textPainter.height / 2));
  }
}
