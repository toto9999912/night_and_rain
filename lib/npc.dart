import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 自訂可見性元件
class VisiblePositionComponent extends PositionComponent with HasVisibility {
  VisiblePositionComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
  });
}

/// NPC類，用於遊戲中的非玩家角色
class NPC extends PositionComponent {
  // NPC移動參數
  final double speed = 20.0; // 移動速度
  final double wanderRadius = 100.0; // 隨機漫步半徑
  final double decisionCooldown = 3.0; // 做決定的冷卻時間(秒)
  double timeSinceLastDecision = 0.0;

  // NPC狀態
  Vector2 moveDirection = Vector2.zero();
  Vector2 startPosition; // 初始位置，用作漫步中心點
  String state = 'idle'; // idle, walking

  // NPC外觀和類型
  final String type; // villager, merchant, guard
  final String id; // NPC的唯一ID
  final String name; // NPC的名稱
  final Color color;
  final double npcSize;

  // 對話內容
  final List<String> dialogues;

  // 引用地圖以進行碰撞檢查
  final Function(PositionComponent) collisionCheck;

  // 互動提示
  bool showInteractionHint = false;
  late VisiblePositionComponent _interactionHint;

  // 新增: 問候語顯示
  late TextComponent _greetingText;
  late VisiblePositionComponent _greetingComponent;
  bool showGreeting = false;

  // 新增: 是否允許對話
  final bool canTalk;

  // 新增: 問候語列表
  final List<String> greetings;

  NPC({
    required Vector2 initialPosition,
    required this.type,
    required this.color,
    required this.dialogues,
    required this.collisionCheck,
    this.npcSize = 20.0,
    String? id,
    String? name,
    this.canTalk = true, // 預設可以對話
    List<String>? greetings, // 可自訂問候語
  }) : startPosition = initialPosition.clone(),
       id = id ?? '${type}_${math.Random().nextInt(10000)}',
       name = name ?? type.substring(0, 1).toUpperCase() + type.substring(1),
       greetings = greetings ?? ['你好!', '早安!', '日安!'],
       super(
         position: initialPosition,
         size: Vector2.all(npcSize),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    // 添加視覺表現 - 簡單的彩色圓形
    add(
      CircleComponent(
        radius: npcSize / 2,
        paint: Paint()..color = color,
        anchor: Anchor.center,
      ),
    );

    // 添加簡單的眼睛
    final eyeRadius = npcSize / 6;
    final eyeOffset = npcSize / 4;

    add(
      CircleComponent(
        radius: eyeRadius,
        paint: Paint()..color = Colors.white,
        position: Vector2(-eyeOffset, -eyeOffset / 2),
        anchor: Anchor.center,
      ),
    );

    add(
      CircleComponent(
        radius: eyeRadius,
        paint: Paint()..color = Colors.white,
        position: Vector2(eyeOffset, -eyeOffset / 2),
        anchor: Anchor.center,
      ),
    );

    // 創建互動提示容器，使用 HasVisibility
    // 創建互動提示容器，使用 HasVisibility
    _interactionHint = VisiblePositionComponent(
      position: Vector2(0, -npcSize / 2 - 15),
      anchor: Anchor.bottomCenter,
    )..add(
      TextComponent(
        text: '!',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 20.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cubic11',
          ),
        ),
        anchor: Anchor.bottomCenter,
      ),
    );
    // 創建互動提示容器
    _interactionHint = VisiblePositionComponent(
      position: Vector2(0, -npcSize / 2 - 15),
      anchor: Anchor.bottomCenter,
    )..add(
      TextComponent(
        text: 'E 按下對話',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 16.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cubic11',
          ),
        ),
        anchor: Anchor.bottomCenter,
      ),
    );
    // 初始為隱藏
    _interactionHint.isVisible = false;
    add(_interactionHint);

    // 新增: 創建問候語容器
    _greetingComponent = VisiblePositionComponent(
      position: Vector2(0, -npcSize / 2 - 40),
      anchor: Anchor.bottomCenter,
    )..add(
      _greetingText = TextComponent(
        text: getRandomGreeting(),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.white,
            backgroundColor: Color(0x88000000),
          ),
        ),
        anchor: Anchor.bottomCenter,
      ),
    );

    // 初始為隱藏
    _greetingComponent.isVisible = false;
    add(_greetingComponent);

    // 初始為隱藏
    _interactionHint.isVisible = false;
    add(_interactionHint);

    await super.onLoad();
  }

  // 設置互動提示的顯示狀態
  void setInteractionHintVisible(bool visible) {
    if (canTalk) {
      _interactionHint.isVisible = visible;
    }
  }

  // 新增: 設置問候語的顯示狀態
  void setGreetingVisible(bool visible) {
    if (visible && !_greetingComponent.isVisible) {
      // 每次顯示時更新問候語
      _greetingText.text = getRandomGreeting();
    }
    _greetingComponent.isVisible = visible;
  }

  // 新增: 獲取隨機問候語
  String getRandomGreeting() {
    final random = math.Random();
    return greetings[random.nextInt(greetings.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新決策計時器
    timeSinceLastDecision += dt;

    // 根據當前狀態行為
    switch (state) {
      case 'idle':
        if (timeSinceLastDecision > decisionCooldown) {
          _makeDecision();
        }
        break;

      case 'walking':
        // 移動NPC
        final proposedMove = position + moveDirection * speed * dt;

        // 臨時添加碰撞檢測
        final tempComponent = PositionComponent(
          position: proposedMove,
          size: Vector2.all(npcSize),
          anchor: Anchor.center,
        );

        // 檢查與障礙物的碰撞
        if (!collisionCheck(tempComponent)) {
          position = proposedMove;
        } else {
          // 遇到障礙物時改變方向
          _makeDecision();
        }

        // 檢查是否已經漫步得太遠
        if (position.distanceTo(startPosition) > wanderRadius) {
          // 朝回家的方向走
          moveDirection = (startPosition - position).normalized();
        }

        if (timeSinceLastDecision > decisionCooldown) {
          _makeDecision();
        }
        break;
    }
  }

  void _makeDecision() {
    final random = math.Random();
    timeSinceLastDecision = 0.0;

    // 決定下一個狀態
    if (state == 'idle') {
      // 有70%的機率開始走動
      if (random.nextDouble() < 0.7) {
        state = 'walking';

        // 選擇隨機方向
        final angle = random.nextDouble() * 2 * math.pi;
        moveDirection = Vector2(math.cos(angle), math.sin(angle));
      }
    } else {
      // 有30%的機率停下來休息
      if (random.nextDouble() < 0.3) {
        state = 'idle';
        moveDirection = Vector2.zero();
      } else {
        // 改變方向
        final angle = random.nextDouble() * 2 * math.pi;
        moveDirection = Vector2(math.cos(angle), math.sin(angle));
      }
    }
  }

  String getRandomDialogue() {
    final random = math.Random();
    return dialogues[random.nextInt(dialogues.length)];
  }
}

/// NPC工廠類，用於根據類型創建不同的NPC
class NPCFactory {
  static NPC createVillager({
    required Vector2 position,
    required Function(PositionComponent) collisionCheck,
  }) {
    return NPC(
      initialPosition: position,
      type: 'villager',
      color: Colors.green[700]!,
      dialogues: ['今天天氣真好啊！', '你好，旅行者！', '我家在村子的東邊。', '這個村子最近很和平。'],
      greetings: ['早安！', '今天真好！', '你好啊！'],
      collisionCheck: collisionCheck,
      canTalk: true,
    );
  }

  static NPC createMerchant({
    required Vector2 position,
    required Function(PositionComponent) collisionCheck,
  }) {
    return NPC(
      initialPosition: position,
      type: 'merchant',
      color: Colors.amber[800]!,
      dialogues: ['想買些什麼嗎？我有最好的商品！', '特價商品！今天折扣！', '我的貨物來自各地。', '我收購各種裝備和材料。'],
      greetings: ['歡迎光臨！', '需要些什麼？', '今日特價！'],
      npcSize: 25.0,
      collisionCheck: collisionCheck,
      canTalk: true,
    );
  }

  static NPC createGuard({
    required Vector2 position,
    required Function(PositionComponent) collisionCheck,
  }) {
    return NPC(
      initialPosition: position,
      type: 'guard',
      color: Colors.blue[800]!,
      dialogues: [
        '保持警惕，最近有怪物出沒。',
        '我在這裡守衛村莊。',
        '有什麼可疑的事情要報告嗎？',
        '村長的房子在北邊，有事找他。',
      ],
      greetings: ['站住！', '一切正常？', '注意安全。'],
      npcSize: 22.0,
      collisionCheck: collisionCheck,
      canTalk: true,
    );
  }
}
