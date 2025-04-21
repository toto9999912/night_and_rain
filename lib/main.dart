import 'dart:math' as math;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';

import 'bullet.dart';
import 'npc.dart';
import 'player.dart';
import 'ui/health_mana_hud.dart';
import 'ui/hotkeys_hud.dart'; // 快捷鍵 HUD 導入
import 'ui/current_weapon_hud.dart'; // 新增當前武器 HUD 導入
import 'village_map.dart';
import 'screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  runApp(const NightAndRainApp());
}

class NightAndRainApp extends StatelessWidget {
  const NightAndRainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Night and Rain',
      theme: ThemeData(
        fontFamily: 'Cubic11',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

/// 主遊戲類 - 管理主要遊戲邏輯和輸入
class NightAndRainGame extends FlameGame
    with KeyboardEvents, MouseMovementDetector, TapDetector {
  // 主要遊戲元素
  late final Player player;
  late final CameraComponent cameraComponent;
  late final GameWorld gameWorld;
  late final HotkeysHud hotkeysHud; // 添加快捷鍵 HUD 引用

  // 設置
  final Vector2 mapSize = Vector2(3000, 3000);
  Vector2 mousePosition = Vector2.zero();

  // 專用UI層 - 用於HUD和其他不受相機影響的UI元件
  late final Component uiLayer;

  // 消息顯示相關屬性
  TextComponent? _messageComponent;
  Timer? _messageTimer;

  @override
  Future<void> onLoad() async {
    await _setupGameWorld();
    await _setupPlayer();
    await _setupCamera();
    await _setupUI();

    await super.onLoad();
  }

  /// 設置遊戲世界和所有地圖相關組件
  Future<void> _setupGameWorld() async {
    gameWorld = GameWorld(mapSize);
    add(gameWorld);
  }

  /// 設置玩家角色
  Future<void> _setupPlayer() async {
    player = Player(mapSize);
    gameWorld.add(player);
  }

  /// 設置遊戲相機
  Future<void> _setupCamera() async {
    cameraComponent = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center;
    add(cameraComponent);
    cameraComponent.follow(player);

    // 使用相機的 viewport 添加 HUD
    final hud = HealthManaHud();
    cameraComponent.viewport.add(hud);
    // 設置相機跟隨玩家
    cameraComponent.follow(player);
  }

  /// 設置UI層和HUD組件
  Future<void> _setupUI() async {
    // 創建UI層，固定位置，不會隨著相機移動
    uiLayer = Component(priority: 100);
    add(uiLayer);

    // 創建并添加快捷鍵 HUD
    hotkeysHud = HotkeysHud();
    print("【調試】初始化熱鍵欄: $hotkeysHud");
    cameraComponent.viewport.add(hotkeysHud);

    // 添加當前武器 HUD，放在 hotkeysHud 左側
    final currentWeaponHud = CurrentWeaponHud();
    cameraComponent.viewport.add(currentWeaponHud);
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
      position: Vector2(size.x / 2, 50),
    );

    world.add(_messageComponent!);

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

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    // 如果背包或角色面板開啟，且按下的是數字鍵1-4，則優先處理物品綁定
    if (player.inventory.isUIVisible && event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1 ||
          event.logicalKey == LogicalKeyboardKey.digit2 ||
          event.logicalKey == LogicalKeyboardKey.digit3 ||
          event.logicalKey == LogicalKeyboardKey.digit4) {
        print("【調試】主遊戲接收到數字鍵: ${event.logicalKey}，將轉發給背包UI處理");

        // 直接獲取背包UI實例並轉發事件
        final inventoryUI = player.inventory.inventoryUI;
        if (inventoryUI.isBindingHotkey) {
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

          if (inventoryUI.bindingItemIndex != null) {
            inventoryUI.bindSelectedItemToHotkey(hotkeySlot);
          }
          return KeyEventResult.handled;
        }
      }
    }

    // 處理「i」鍵打開/關閉背包
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyI) {
      player.toggleInventory();
      return KeyEventResult.handled;
    }

    // 處理「c」鍵打開/關閉角色面板
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyC) {
      player.toggleCharacterPanel();
      return KeyEventResult.handled;
    }

    // 處理數字鍵 1-4 快捷鍵
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        hotkeysHud.useHotkey(0);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
        hotkeysHud.useHotkey(1);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
        hotkeysHud.useHotkey(2);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.digit4) {
        hotkeysHud.useHotkey(3);
        return KeyEventResult.handled;
      }
    }

    // 只有當背包、角色面板和對話系統未打開時才處理移動和射擊
    if (!player.inventory.isUIVisible) {
      player.updateMovement(keysPressed);

      // 空格鍵射擊
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.space) {
        player.shoot();
      } else if (event is KeyUpEvent &&
          event.logicalKey == LogicalKeyboardKey.space) {
        player.stopShooting();
      }
    } else {
      // 如果UI打開中，則停止角色移動和射擊
      player.movement.stopMovement();
      player.stopShooting();
    }

    return KeyEventResult.handled;
  }

  // 處理滑鼠移動
  @override
  void onMouseMove(PointerHoverInfo info) {
    mousePosition = cameraComponent.globalToLocal(info.eventPosition.global);
    player.updateWeaponAngle(mousePosition);
  }

  // 處理點擊/觸摸
  @override
  void onTapDown(TapDownInfo info) {
    mousePosition = cameraComponent.globalToLocal(info.eventPosition.global);
    player.updateWeaponAngle(mousePosition);
    player.shoot();
  }

  @override
  void onTapUp(TapUpInfo info) {
    player.stopShooting();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新消息計時器
    if (_messageTimer != null && !_messageTimer!.finished) {
      _messageTimer!.update(dt);
    }
  }
}

/// 遊戲世界 - 包含所有遊戲元素，如地圖、NPC、子彈等
class GameWorld extends World {
  final Vector2 mapSize;
  late VillageMap villageMap;
  final List<Bullet> bullets = [];
  final List<NPC> npcs = [];

  GameWorld(this.mapSize);

  @override
  Future<void> onLoad() async {
    await _setupMap();
    _spawnNPCs();
    await super.onLoad();
  }

  /// 設置地圖
  Future<void> _setupMap() async {
    villageMap = VillageMap(mapSize);
    add(villageMap);
    add(MapBorder(mapSize));
  }

  /// 生成NPC
  void _spawnNPCs() {
    final random = math.Random();

    // 生成不同類型的NPC
    _spawnNPCsByType(NPCType.villager, 5 + random.nextInt(3), random);
    _spawnNPCsByType(NPCType.merchant, 2 + random.nextInt(2), random);
    _spawnNPCsByType(NPCType.guard, 3 + random.nextInt(2), random);
  }

  /// 根據類型生成特定數量的NPC
  void _spawnNPCsByType(NPCType type, int count, math.Random random) {
    for (int i = 0; i < count; i++) {
      final position = _getRandomValidPosition(random);

      NPC npc;
      switch (type) {
        case NPCType.villager:
          npc = NPCFactory.createVillager(
            position: position,
            collisionCheck: checkCollision,
          );
          break;
        case NPCType.merchant:
          npc = NPCFactory.createMerchant(
            position: position,
            collisionCheck: checkCollision,
          );
          break;
        case NPCType.guard:
          npc = NPCFactory.createGuard(
            position: position,
            collisionCheck: checkCollision,
          );
          break;
      }

      add(npc);
      npcs.add(npc);
    }
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

      position = Vector2(
        centerX + math.cos(angle) * distance,
        centerY + math.sin(angle) * distance,
      );

      // 檢查位置是否有效
      final tempComponent = PositionComponent(
        position: position,
        size: Vector2.all(20.0),
        anchor: Anchor.center,
      );

      validPosition = !checkCollision(tempComponent);
    }

    return position;
  }

  /// 檢查是否與障礙物碰撞
  bool checkCollision(PositionComponent component) {
    return villageMap.checkCollision(component);
  }

  /// 添加子彈到遊戲世界
  void addBullet(
    Vector2 position,
    Vector2 direction,
    double speed,
    double damage, {
    Color? bulletColor,
    Vector2? bulletSize,
  }) {
    final bullet = Bullet(
      position: position,
      direction: direction.normalized(),
      speed: speed,
      damage: damage,
      bulletColor: bulletColor,
      bulletSize: bulletSize,
    );
    add(bullet);
    bullets.add(bullet);
  }

  /// 與最近的NPC互動
  NPC? interactWithNearestNPC(
    Vector2 playerPosition, {
    double maxDistance = 50.0,
  }) {
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

  /// 清理已經標記為應移除的子彈
  void cleanupBullets() {
    bullets.where((b) => b.shouldRemove).toList().forEach((b) {
      b.removeFromParent();
      bullets.remove(b);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    cleanupBullets();
  }
}

/// 地圖邊界 - 視覺上顯示地圖邊界
class MapBorder extends PositionComponent {
  MapBorder(Vector2 mapSize) : super(size: mapSize);

  @override
  Future<void> onLoad() async {
    add(
      RectangleComponent(
        size: size,
        paint:
            Paint()
              ..color = Colors.red
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5.0,
      ),
    );
    await super.onLoad();
  }
}

/// NPC類型枚舉 - 用於更容易地生成特定類型的NPC
enum NPCType { villager, merchant, guard }
