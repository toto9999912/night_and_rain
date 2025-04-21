import 'dart:async';
import '../models/enums.dart';

/// 基本遊戲事件類型
abstract class GameEvent {
  final GameEventType type;

  GameEvent(this.type);
}

/// 玩家受傷事件
class PlayerDamagedEvent extends GameEvent {
  final double damage;
  final String source;

  PlayerDamagedEvent({required this.damage, required this.source}) : super(GameEventType.playerDamaged);
}

/// NPC 互動事件
class NPCInteractionEvent extends GameEvent {
  final String npcId;
  final String npcName;

  NPCInteractionEvent({required this.npcId, required this.npcName}) : super(GameEventType.npcInteraction);
}

/// 物品收集事件
class ItemCollectedEvent extends GameEvent {
  final String itemId;
  final String itemName;

  ItemCollectedEvent({required this.itemId, required this.itemName}) : super(GameEventType.itemCollected);
}

/// 事件總線 - 單例模式實現系統間通信
class GameEventBus {
  static final GameEventBus _instance = GameEventBus._();
  final _eventStream = StreamController<GameEvent>.broadcast();

  GameEventBus._();
  factory GameEventBus() => _instance;

  /// 監聽特定類型的事件
  Stream<T> on<T extends GameEvent>() => _eventStream.stream.where((e) => e is T).cast<T>();

  /// 發送事件
  void fire(GameEvent event) => _eventStream.add(event);

  /// 關閉事件流
  void dispose() {
    _eventStream.close();
  }
}
