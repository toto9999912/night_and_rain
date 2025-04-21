import 'package:flame/components.dart';
import '../village_map.dart';

/// 專責處理遊戲中碰撞檢測的系統
class CollisionSystem {
  final VillageMap map;

  CollisionSystem(this.map);

  /// 檢查組件是否與地圖上的障礙物碰撞
  bool checkCollision(PositionComponent component) {
    return map.checkCollision(component);
  }
}
