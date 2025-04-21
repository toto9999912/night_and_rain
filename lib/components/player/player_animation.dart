import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

/// 玩家動畫狀態
enum PlayerState { idle, walking, dead }

/// 專門處理玩家動畫的類別
class PlayerAnimation {
  // 動畫相關屬性
  late final Map<PlayerState, SpriteAnimation> animations;
  PlayerState currentState = PlayerState.idle;
  SpriteAnimationGroupComponent<PlayerState> component;

  // 儲存步驟時間，因為無法從 SpriteAnimation 直接讀取
  double originalWalkingStepTime = 0.15;

  PlayerAnimation(this.component);

  Future<void> loadAnimations() async {
    // 載入精靈圖
    final image = await Flame.images.load('player.png');
    final double animStepTime = 0.1; // 動畫速度

    // 新的精靈圖尺寸 (864/3 = 288)
    final spriteSize = Vector2(288, 288);

    // 創建空列表來存儲所有8個影格
    final List<Sprite> allSprites = [];

    // 從3x3的排版中讀取8個影格，最後一格是空白的
    for (int y = 0; y < 3; y++) {
      for (int x = 0; x < 3; x++) {
        // 跳過最後一格 (2,2) 因為它是空白的
        if (y == 2 && x == 2) continue;

        allSprites.add(
          Sprite(
            image,
            srcPosition: Vector2(x * spriteSize.x, y * spriteSize.y),
            srcSize: spriteSize,
          ),
        );
      }
    }

    // 創建動畫 - 所有狀態暫時使用相同的動畫
    final commonAnimation = SpriteAnimation.spriteList(
      allSprites,
      stepTime: animStepTime,
      loop: true,
    );

    // 使用同一動畫用於所有狀態
    animations = {
      PlayerState.idle: commonAnimation,
      PlayerState.walking: commonAnimation,
      PlayerState.dead: commonAnimation, // 死亡動畫暫時也使用相同的精靈圖但不循環
    };

    // 保存步驟時間供後續使用
    originalWalkingStepTime = animStepTime;

    // 將動畫設置到組件
    component.animations = animations;
    changeState(PlayerState.idle);
  }

  void setupAnimationSpeedControl() {
    // 由於這部分需要和 TimerComponent 整合，將在 Player 類中實現
  }

  void changeState(PlayerState state) {
    if (currentState != state) {
      currentState = state;
      component.current = state;
    }
  }

  void updateAnimationState(Vector2 velocity, double maxSpeed, bool isDead) {
    if (isDead) {
      changeState(PlayerState.dead);
      return;
    }

    // 添加平滑過渡
    if (velocity.length > maxSpeed * 0.1) {
      // 只有速度足夠大時才切換到行走
      changeState(PlayerState.walking);
    } else {
      // 速度很小時切換到靜止
      changeState(PlayerState.idle);
    }

    // 處理角色面向，保持平滑過渡
    if (velocity.x != 0) {
      // 平滑翻轉
      final targetScaleX = velocity.x < 0 ? -1.0 : 1.0;
      component.scale.x = component.scale.x * 0.9 + targetScaleX * 0.1; // 平滑插值
    }
  }

  void adjustWalkingAnimationSpeed(
    Vector2 velocity,
    double maxSpeed,
    double gameTime,
  ) {
    if (currentState == PlayerState.walking && animations != null) {
      // 根據實際移動速度調整動畫速度
      final speedRatio = velocity.length / maxSpeed;
      final newStepTime = originalWalkingStepTime / math.max(0.5, speedRatio);
      final clampedStepTime = newStepTime.clamp(0.08, 0.3);
      animations[PlayerState.walking]!.stepTime = clampedStepTime;

      // 在很慢的移動中平滑過渡到idle動畫
      if (velocity.length < maxSpeed * 0.2) {
        // 混合靜止和行走動畫
        final blendRatio = velocity.length / (maxSpeed * 0.2);
        blendToIdle(1 - blendRatio, gameTime);
      }
    }
  }

  void blendToIdle(double idleRatio, double gameTime) {
    // 調整動畫速度
    animations[PlayerState.walking]!.stepTime = math.max(
      originalWalkingStepTime,
      originalWalkingStepTime + idleRatio * 0.1,
    );

    // 添加微小的"呼吸"效果
    final breathEffect = math.sin(gameTime * 2) * 0.01 * idleRatio;
    component.scale.y = 1.0 + breathEffect;
  }
}
