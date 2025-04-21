import 'dart:math' as math;
import 'package:flame/components.dart';
import '../models/enums.dart';
import '../npc.dart';

/// 專責管理遊戲中 NPC 相關功能的類別
class NPCManager {
  final List<NPC> npcs = [];
  final Vector2 mapSize;
  final Function(PositionComponent) collisionCheck;

  NPCManager(this.mapSize, this.collisionCheck);

  /// 生成所有類型的 NPC
  void spawnNPCs() {
    final random = math.Random();

    // 生成不同類型的 NPC
    _spawnNPCsByType(NPCType.villager, 5 + random.nextInt(3), random);
    _spawnNPCsByType(NPCType.merchant, 2 + random.nextInt(2), random);
    _spawnNPCsByType(NPCType.guard, 3 + random.nextInt(2), random);
  }

  /// 根據類型生成特定數量的 NPC
  void _spawnNPCsByType(NPCType type, int count, math.Random random) {
    for (int i = 0; i < count; i++) {
      final position = _getRandomValidPosition(random);

      NPC npc;
      switch (type) {
        case NPCType.villager:
          npc = NPCFactory.createVillager(position: position, collisionCheck: collisionCheck);
          break;
        case NPCType.merchant:
          npc = NPCFactory.createMerchant(position: position, collisionCheck: collisionCheck);
          break;
        case NPCType.guard:
          npc = NPCFactory.createGuard(position: position, collisionCheck: collisionCheck);
          break;
      }

      // 返回 NPC 實例，讓呼叫者負責添加到遊戲世界
      npcs.add(npc);
    }
  }

  /// 尋找最近的 NPC 進行互動
  NPC? findNearestNPC(Vector2 playerPosition, {double maxDistance = 50.0}) {
    NPC? nearestNPC;
    double minDistance = maxDistance;

    for (final npc in npcs) {
      final distance = npc.position.distanceTo(playerPosition);
      if (distance < minDistance) {
        minDistance = distance;
        nearestNPC = npc;
      }
    }

    return nearestNPC;
  }

  /// 獲取隨機有效位置（不與障礙物碰撞）
  Vector2 _getRandomValidPosition(math.Random random) {
    Vector2 position = Vector2.zero();
    bool validPosition = false;

    while (!validPosition) {
      // 生成村莊中心區域附近的隨機位置
      final centerX = mapSize.x / 2;
      final centerY = mapSize.y / 2;
      final radius = math.min(mapSize.x, mapSize.y) * 0.3;

      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * radius;

      position = Vector2(centerX + math.cos(angle) * distance, centerY + math.sin(angle) * distance);

      // 檢查位置是否有效
      final tempComponent = PositionComponent(position: position, size: Vector2.all(20.0), anchor: Anchor.center);

      validPosition = !collisionCheck(tempComponent);
    }

    return position;
  }
}
