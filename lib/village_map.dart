import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class VillageMap extends Component {
  final Vector2 mapSize;
  final Vector2 position;

  // 畫筆設定
  final Paint grassPaint = Paint()..color = const Color(0xFF7EC850); // 草地顏色
  final Paint pathPaint = Paint()..color = const Color(0xFFDDBB76); // 泥土路徑
  final Paint waterPaint = Paint()..color = const Color(0xFF4A90E2); // 水池顏色
  final Paint buildingPaint = Paint()..color = const Color(0xFFBF8969); // 建築顏色
  final Paint roofPaint = Paint()..color = const Color(0xFFA0522D); // 屋頂顏色
  final Paint stonePaint = Paint()..color = const Color(0xFF9E9E9E); // 石頭顏色

  // 物件集合
  final List<PositionComponent> buildings = [];
  final List<PositionComponent> decorations = [];
  final List<PositionComponent> obstacles = [];

  // 村莊設置
  final int buildingCount = 6; // 建築數量
  final double buildingMinSize = 70; // 最小建築尺寸
  final double buildingMaxSize = 100; // 最大建築尺寸

  // 定義區域
  late Rect centralPlaza; // 中央廣場
  late Rect pond; // 池塘
  final List<Rect> buildingAreas = []; // 建築區域

  VillageMap(this.mapSize, {Vector2? position})
    : position = position ?? Vector2.zero();

  @override
  Future<void> onLoad() async {
    // 綠色草地背景
    add(
      RectangleComponent(position: position, size: mapSize, paint: grassPaint),
    );

    // 生成村莊地圖
    _createVillageLayout();

    // 添加建築物
    _addBuildings();

    // 添加小路
    _addPaths();

    // 添加裝飾和細節
    _addDecorations();

    await super.onLoad();
  }

  void _createVillageLayout() {
    final random = math.Random();

    // 1. 創建中央廣場
    final plazaSize = math.min(mapSize.x, mapSize.y) * 0.25;
    centralPlaza = Rect.fromCenter(
      center: Offset(mapSize.x / 2, mapSize.y / 2),
      width: plazaSize,
      height: plazaSize,
    );

    // 繪製中央廣場
    add(
      RectangleComponent(
        position: position + Vector2(centralPlaza.left, centralPlaza.top),
        size: Vector2(centralPlaza.width, centralPlaza.height),
        paint: pathPaint,
      ),
    );

    // 2. 創建池塘
    final pondSize = plazaSize * 0.6;
    final pondOffsetX = mapSize.x * (0.3 + random.nextDouble() * 0.1);
    final pondOffsetY = mapSize.y * (0.3 + random.nextDouble() * 0.1);

    pond = Rect.fromCenter(
      center: Offset(pondOffsetX, pondOffsetY),
      width: pondSize,
      height: pondSize * 0.8, // 略微橢圓形
    );

    // 繪製池塘 (使用圓形)
    add(
      CircleComponent(
        position: position + Vector2(pond.center.dx, pond.center.dy),
        radius: pondSize / 2,
        paint: waterPaint,
        anchor: Anchor.center,
      ),
    );

    // 3. 定義建築區域
    _defineBuilidingAreas();
  }

  void _defineBuilidingAreas() {
    final random = math.Random();
    final areaCount = 4; // 定義四個主要建築區域

    // 區域角度和距離
    final angles = [
      math.pi / 4, // 右上
      3 * math.pi / 4, // 左上
      5 * math.pi / 4, // 左下
      7 * math.pi / 4, // 右下
    ];

    final centerX = mapSize.x / 2;
    final centerY = mapSize.y / 2;
    final distanceFromCenter = math.min(mapSize.x, mapSize.y) * 0.3;

    // 創建建築區域
    for (int i = 0; i < areaCount; i++) {
      final angle = angles[i];

      // 確定區域中心點
      final areaX = centerX + math.cos(angle) * distanceFromCenter;
      final areaY = centerY + math.sin(angle) * distanceFromCenter;

      // 區域大小
      final areaWidth = 200.0 + random.nextDouble() * 50;
      final areaHeight = 200.0 + random.nextDouble() * 50;

      // 建築區域
      final buildingArea = Rect.fromCenter(
        center: Offset(areaX, areaY),
        width: areaWidth,
        height: areaHeight,
      );

      buildingAreas.add(buildingArea);
    }
  }

  void _addBuildings() {
    final random = math.Random();

    // 給每個建築區域分配建築
    for (int areaIndex = 0; areaIndex < buildingAreas.length; areaIndex++) {
      final area = buildingAreas[areaIndex];

      // 每個區域隨機建築數量 (1-2棟)
      final buildingsInArea = 1 + random.nextInt(1);

      for (int i = 0; i < buildingsInArea; i++) {
        // 建築尺寸
        final buildingWidth =
            buildingMinSize +
            random.nextDouble() * (buildingMaxSize - buildingMinSize);
        final buildingHeight =
            buildingMinSize +
            random.nextDouble() * (buildingMaxSize - buildingMinSize);

        // 建築位置 (在區域內隨機)
        final buildingX =
            area.left + random.nextDouble() * (area.width - buildingWidth);
        final buildingY =
            area.top + random.nextDouble() * (area.height - buildingHeight);

        // 創建建築底座
        final building = RectangleComponent(
          position: position + Vector2(buildingX, buildingY),
          size: Vector2(buildingWidth, buildingHeight),
          paint: buildingPaint,
        );

        add(building);
        buildings.add(building);
        obstacles.add(building);

        // 添加屋頂 (三角形)
        final roofLeft = buildingX - 10;
        final roofRight = buildingX + buildingWidth + 10;
        final roofTop = buildingY - buildingHeight * 0.4;
        final roofBottom = buildingY;

        // 使用 PolygonComponent 創建三角形屋頂
        final roofVerticies = [
          Vector2(roofLeft, roofBottom),
          Vector2((roofLeft + roofRight) / 2, roofTop),
          Vector2(roofRight, roofBottom),
        ];

        final roof = PolygonComponent(
          roofVerticies,
          paint: roofPaint,
          position: position,
        );

        add(roof);

        // 添加簡單的門
        final doorWidth = buildingWidth * 0.3;
        final doorHeight = buildingHeight * 0.4;
        final doorX = buildingX + (buildingWidth - doorWidth) / 2;
        final doorY = buildingY + buildingHeight - doorHeight;

        final door = RectangleComponent(
          position: position + Vector2(doorX, doorY),
          size: Vector2(doorWidth, doorHeight),
          paint: Paint()..color = Colors.brown[900]!,
        );

        add(door);

        // 添加窗戶
        if (random.nextBool()) {
          final windowSize = buildingWidth * 0.2;
          final windowX = buildingX + buildingWidth * 0.2;
          final windowY = buildingY + buildingHeight * 0.3;

          final window = RectangleComponent(
            position: position + Vector2(windowX, windowY),
            size: Vector2(windowSize, windowSize),
            paint: Paint()..color = Colors.lightBlueAccent.withOpacity(0.7),
          );

          add(window);
        }
      }
    }

    // 特殊建築: 中央廣場的小亭子
    final gazeboSize = centralPlaza.width * 0.4;
    final gazeboX = centralPlaza.center.dx - gazeboSize / 2;
    final gazeboY = centralPlaza.center.dy - gazeboSize / 2;

    // 亭子底座
    final gazebo = RectangleComponent(
      position: position + Vector2(gazeboX, gazeboY),
      size: Vector2(gazeboSize, gazeboSize),
      paint: stonePaint,
    );

    add(gazebo);
    buildings.add(gazebo);

    // 亭子屋頂
    final gazeboRoofSize = gazeboSize * 1.3;
    final gazeboRoofX = gazeboX - (gazeboRoofSize - gazeboSize) / 2;
    final gazeboRoofY = gazeboY - gazeboSize * 0.3;

    final gazeboRoof = RectangleComponent(
      position: position + Vector2(gazeboRoofX, gazeboRoofY),
      size: Vector2(gazeboRoofSize, gazeboRoofSize * 0.2),
      paint: roofPaint,
    );

    add(gazeboRoof);
  }

  void _addPaths() {
    final pathWidth = 30.0;

    // 從中央廣場到各個建築區域的路徑
    for (final area in buildingAreas) {
      // 計算路徑起點 (中央廣場中心)
      final startX = centralPlaza.center.dx;
      final startY = centralPlaza.center.dy;

      // 計算路徑終點 (建築區域中心)
      final endX = area.center.dx;
      final endY = area.center.dy;

      // 計算路徑方向角度
      final angle = math.atan2(endY - startY, endX - startX);

      // 計算路徑長度
      final pathLength = math.sqrt(
        math.pow(endX - startX, 2) + math.pow(endY - startY, 2),
      );

      // 創建路徑
      final path = RectangleComponent(
        position: position + Vector2(startX, startY),
        size: Vector2(pathLength, pathWidth),
        angle: angle,
        anchor: Anchor.centerLeft,
        paint: pathPaint,
      );

      add(path);
    }

    // 從中央廣場到池塘的路徑
    final plazaToPondPath = RectangleComponent(
      position:
          position + Vector2(centralPlaza.center.dx, centralPlaza.center.dy),
      size: Vector2(
        math.sqrt(
          math.pow(pond.center.dx - centralPlaza.center.dx, 2) +
              math.pow(pond.center.dy - centralPlaza.center.dy, 2),
        ),
        pathWidth,
      ),
      angle: math.atan2(
        pond.center.dy - centralPlaza.center.dy,
        pond.center.dx - centralPlaza.center.dx,
      ),
      anchor: Anchor.centerLeft,
      paint: pathPaint,
    );

    add(plazaToPondPath);
  }

  void _addDecorations() {
    final random = math.Random();

    // 在池塘周圍添加石頭
    final stoneCount = 8 + random.nextInt(5);
    for (int i = 0; i < stoneCount; i++) {
      final angle = i * (2 * math.pi / stoneCount);
      final distance = pond.width / 2 + 10.0 + random.nextDouble() * 20;

      final stoneX = pond.center.dx + math.cos(angle) * distance;
      final stoneY = pond.center.dy + math.sin(angle) * distance;

      final stoneSize = 5.0 + random.nextDouble() * 10;

      final stone = CircleComponent(
        position: position + Vector2(stoneX, stoneY),
        radius: stoneSize,
        paint: stonePaint,
        anchor: Anchor.center,
      );

      add(stone);
      decorations.add(stone);
    }

    // 中央廣場裝飾 - 幾處花壇
    _addFlowerBeds();

    // 村莊周圍的樹木
    _addTrees();

    // 雜項裝飾 - 木桶、箱子等
    _addMiscDecorations();
  }

  void _addFlowerBeds() {
    final random = math.Random();

    // 中央廣場的四個角落添加花壇
    final flowerBedSize = 20.0;
    final flowerBedPadding = 10.0;

    // 花壇位置 (廣場四個角落)
    final flowerBedPositions = [
      Vector2(
        centralPlaza.left + flowerBedPadding,
        centralPlaza.top + flowerBedPadding,
      ),
      Vector2(
        centralPlaza.right - flowerBedPadding - flowerBedSize,
        centralPlaza.top + flowerBedPadding,
      ),
      Vector2(
        centralPlaza.left + flowerBedPadding,
        centralPlaza.bottom - flowerBedPadding - flowerBedSize,
      ),
      Vector2(
        centralPlaza.right - flowerBedPadding - flowerBedSize,
        centralPlaza.bottom - flowerBedPadding - flowerBedSize,
      ),
    ];

    for (final bedPos in flowerBedPositions) {
      final flowerBed = RectangleComponent(
        position: position + bedPos,
        size: Vector2(flowerBedSize, flowerBedSize),
        paint: Paint()..color = Colors.brown[600]!,
      );

      add(flowerBed);

      // 花朵
      for (int i = 0; i < 3; i++) {
        final flowerX = bedPos.x + random.nextDouble() * flowerBedSize;
        final flowerY = bedPos.y + random.nextDouble() * flowerBedSize;

        // 隨機花色
        final flowerColors = [
          Colors.red[400]!,
          Colors.yellow[400]!,
          Colors.purple[300]!,
          Colors.pink[300]!,
        ];

        final flower = CircleComponent(
          position: position + Vector2(flowerX, flowerY),
          radius: 3.0,
          paint:
              Paint()
                ..color = flowerColors[random.nextInt(flowerColors.length)],
          anchor: Anchor.center,
        );

        add(flower);
        decorations.add(flower);
      }
    }
  }

  void _addTrees() {
    final random = math.Random();

    // 邊界附近添加樹木
    final treeCount = 40;
    for (int i = 0; i < treeCount; i++) {
      // 決定樹的位置 (主要在地圖邊緣)
      double treeX;
      double treeY;

      if (i < treeCount / 4) {
        // 上邊界
        treeX = random.nextDouble() * mapSize.x;
        treeY = random.nextDouble() * 100;
      } else if (i < treeCount / 2) {
        // 右邊界
        treeX = mapSize.x - random.nextDouble() * 100;
        treeY = random.nextDouble() * mapSize.y;
      } else if (i < 3 * treeCount / 4) {
        // 下邊界
        treeX = random.nextDouble() * mapSize.x;
        treeY = mapSize.y - random.nextDouble() * 100;
      } else {
        // 左邊界
        treeX = random.nextDouble() * 100;
        treeY = random.nextDouble() * mapSize.y;
      }

      // 確保樹不在建築物或道路上
      bool validPosition = true;
      for (final building in buildings) {
        if (_pointInRect(
          Vector2(treeX, treeY),
          building.position,
          building.size,
        )) {
          validPosition = false;
          break;
        }
      }

      if (!validPosition) continue;

      // 樹幹
      final trunkWidth = 10.0;
      final trunkHeight = 20.0;
      final trunk = RectangleComponent(
        position:
            position + Vector2(treeX - trunkWidth / 2, treeY - trunkHeight / 2),
        size: Vector2(trunkWidth, trunkHeight),
        paint: Paint()..color = Colors.brown[700]!,
      );

      add(trunk);
      obstacles.add(trunk);

      // 樹冠
      final leafRadius = 15.0 + random.nextDouble() * 10;
      final leaves = CircleComponent(
        position: position + Vector2(treeX, treeY - trunkHeight / 2),
        radius: leafRadius,
        paint: Paint()..color = Colors.green[700]!,
        anchor: Anchor.center,
      );

      add(leaves);
    }
  }

  void _addMiscDecorations() {
    final random = math.Random();

    // 在建築物附近添加小裝飾
    for (final building in buildings) {
      // 只為一些建築添加裝飾
      if (!random.nextBool()) continue;

      final buildingX = building.position.x - position.x;
      final buildingY = building.position.y - position.y;
      final buildingWidth = building.size.x;
      final buildingHeight = building.size.y;

      // 決定裝飾位置 (建築物旁邊)
      final decorOffsetX = buildingWidth + 10.0;
      final decorX = buildingX + (random.nextBool() ? decorOffsetX : -20.0);
      final decorY = buildingY + random.nextDouble() * buildingHeight;

      // 裝飾類型
      final decorTypes = ['barrel', 'crate', 'sign'];
      final decorType = decorTypes[random.nextInt(decorTypes.length)];

      PositionComponent decoration;

      switch (decorType) {
        case 'barrel':
          // 木桶
          decoration = CircleComponent(
            position: position + Vector2(decorX, decorY),
            radius: 10.0,
            paint: Paint()..color = Colors.brown[500]!,
            anchor: Anchor.center,
          );
          break;

        case 'crate':
          // 木箱
          decoration = RectangleComponent(
            position: position + Vector2(decorX - 7.5, decorY - 7.5),
            size: Vector2(15.0, 15.0),
            paint: Paint()..color = Colors.brown[300]!,
          );
          break;

        case 'sign':
          // 指示牌
          decoration = PolygonComponent(
            [Vector2(0, 0), Vector2(15, 0), Vector2(15, -20), Vector2(0, -20)],
            paint: Paint()..color = Colors.brown[400]!,
            position: position + Vector2(decorX, decorY),
          );
          break;

        default:
          // 默認圓形裝飾
          decoration = CircleComponent(
            position: position + Vector2(decorX, decorY),
            radius: 5.0,
            paint: Paint()..color = Colors.grey,
            anchor: Anchor.center,
          );
      }

      add(decoration);
      decorations.add(decoration);
      if (decorType != 'sign') {
        obstacles.add(decoration);
      }
    }
  }

  // 輔助方法 - 判斷點是否在矩形內
  bool _pointInRect(Vector2 point, Vector2 rectPos, Vector2 rectSize) {
    return (point.x >= rectPos.x &&
        point.x <= rectPos.x + rectSize.x &&
        point.y >= rectPos.y &&
        point.y <= rectPos.y + rectSize.y);
  }

  // 輔助方法 - 檢查是否與障礙物碰撞
  bool checkCollision(PositionComponent component) {
    for (final obstacle in obstacles) {
      if (_rectIntersect(component, obstacle)) {
        return true;
      }
    }
    return false;
  }

  // 判斷矩形是否相交
  bool _rectIntersect(PositionComponent a, PositionComponent b) {
    final aRect = a.toRect();
    final bRect = b.toRect();
    return aRect.overlaps(bRect);
  }

  // 判斷位置是否在水中
  bool isInWater(Vector2 position) {
    final distance = Vector2(
      pond.center.dx,
      pond.center.dy,
    ).distanceTo(position);

    return distance < pond.width / 2 - 5; // 略微縮小一點的半徑檢測
  }
}
