import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class Bullet extends PositionComponent with HasGameRef<NightAndRainGame> {
  final Vector2 direction;
  final double speed;
  final double damage;
  final Color bulletColor; // 子彈顏色
  final Vector2 bulletSize; // 子彈大小

  bool shouldRemove = false;
  double lifespan = 2.0; // 子彈存活時間（秒）

  Bullet({required Vector2 position, required this.direction, this.speed = 500.0, this.damage = 10.0, Color? bulletColor, Vector2? bulletSize})
    : bulletColor = bulletColor ?? Colors.amberAccent,
      bulletSize = bulletSize ?? Vector2(16, 8),
      super(position: position, size: bulletSize ?? Vector2(16, 8), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // 繪製矩形作為子彈
    add(RectangleComponent(size: size, paint: Paint()..color = bulletColor, anchor: Anchor.center));

    angle = direction.angleToSigned(Vector2(1, 0));

    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 子彈位置更新
    position += direction * speed * dt;

    // 子彈生命時間管理
    lifespan -= dt;
    if (lifespan <= 0) {
      shouldRemove = true;
    }

    // 子彈碰撞障礙物的處理
    // 使用 GameWorld 中的 checkCollision 方法
    if (gameRef.gameWorld.checkCollision(this)) {
      shouldRemove = true;
      _createHitEffect();
    }
  }

  void _createHitEffect() {
    // 撞擊效果，使用子彈顏色
    final effect = CircleComponent(radius: 10, paint: Paint()..color = bulletColor.withValues(alpha: 0.7), position: position, anchor: Anchor.center);

    gameRef.gameWorld.add(effect);

    // 0.2秒後移除效果
    Future.delayed(const Duration(milliseconds: 200), () {
      effect.removeFromParent();
    });
  }
}
