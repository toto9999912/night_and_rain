import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:night_and_rain/main.dart';
import '../models/scenario_data.dart';
import '../widgets/scenario_card.dart';

class ScenarioSelectionScreen extends StatefulWidget {
  const ScenarioSelectionScreen({super.key});

  @override
  State<ScenarioSelectionScreen> createState() =>
      _ScenarioSelectionScreenState();
}

class _ScenarioSelectionScreenState extends State<ScenarioSelectionScreen>
    with TickerProviderStateMixin {
  // 當前選擇的劇本類型 (主線或支線)
  String _selectedType = '主線';
  int _currentMainIndex = 0;
  int _currentSideIndex = 0;

  // 用於選中劇本放大效果的動畫控制
  double _selectedScale = 1.0;
  bool _isAnimating = false;

  // 主線和支線劇本列表
  final List<ScenarioData> _mainScenarios = MainScenarios.getMainScenarios();
  final List<ScenarioData> _sideScenarios = SideScenarios.getSideScenarios();

  late TabController _tabController;
  final CarouselSliderController _mainCarouselController =
      CarouselSliderController();
  final CarouselSliderController _sideCarouselController =
      CarouselSliderController();

  // 背景粒子動畫控制器
  late AnimationController _particleController;

  // 選中劇本的脈動效果
  bool _pulseEffect = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedType = _tabController.index == 0 ? '主線' : '支線';
        _animateSelection();
      });
    });

    // 初始化粒子控制器
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 啟動脈動效果
    _startPulseEffect();
  }

  // 選中時的動畫效果
  void _animateSelection() {
    setState(() {
      _isAnimating = true;
      _selectedScale = 0.9;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _selectedScale = 1.1;
        });

        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() {
              _selectedScale = 1.0;
              _isAnimating = false;
            });
          }
        });
      }
    });
  }

  // 啟動脈動效果
  void _startPulseEffect() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _pulseEffect = !_pulseEffect;
        });
        _startPulseEffect();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _buildBackButton(),
        centerTitle: true,
        title: _buildAnimatedTitle(),
      ),
      body: Stack(
        children: [
          // 背景層 - 動態粒子效果
          _buildAnimatedBackground(),

          // 主要內容
          SafeArea(
            child: Column(
              children: [
                // Tab選項：主線/支線
                _buildTabBar(),

                // 劇本列表內容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 主線劇本
                      _buildScenarioCarousel(
                        _mainScenarios,
                        _mainCarouselController,
                        _currentMainIndex,
                      ),
                      // 支線劇本
                      _buildScenarioCarousel(
                        _sideScenarios,
                        _sideCarouselController,
                        _currentSideIndex,
                      ),
                    ],
                  ),
                ),

                // 開始按鈕
                _buildStartButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Hero(
      tag: 'back_button',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: const [Colors.blue, Colors.white, Colors.lightBlueAccent],
          stops: [0.0, 0.5, 1.0],
          tileMode: TileMode.clamp,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: const Text(
        '劇本選擇',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white, // 文字最終會顯示漸層色彩
          shadows: [
            Shadow(color: Colors.black87, offset: Offset(2, 2), blurRadius: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          // 漸變底色
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade900,
                  Colors.indigo.shade900,
                  Colors.black,
                ],
              ),
            ),
          ),

          // 浮動粒子效果
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticleBackgroundPainter(
                  animation: _particleController,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 微妙的光暈效果
          Positioned(
            top: -100,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 70,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      height: 55,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.blue.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.blue.shade700,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        unselectedLabelColor: Colors.white70,
        tabs: [_buildAnimatedTab('主線劇情', 0), _buildAnimatedTab('支線任務', 1)],
      ),
    );
  }

  Widget _buildAnimatedTab(String text, int index) {
    final bool isSelected = (_tabController.index == index);

    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.brightness_1, size: 10, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCarousel(
    List<ScenarioData> scenarios,
    CarouselSliderController carouselController,
    int currentIndex,
  ) {
    return Column(
      children: [
        // 上方顯示進度指示器
        _buildProgressIndicator(scenarios, currentIndex),
        const SizedBox(height: 15),

        // 劇本輪播區域 - 使用 CarouselSlider
        Expanded(
          child: CarouselSlider.builder(
            carouselController: carouselController,
            itemCount: scenarios.length,
            options: CarouselOptions(
              height: double.infinity,
              enlargeCenterPage: true,
              enlargeFactor: 0.35,
              viewportFraction: 0.8,
              onPageChanged: (index, reason) {
                setState(() {
                  if (_selectedType == '主線') {
                    if (_currentMainIndex != index) {
                      _currentMainIndex = index;
                      _animateSelection();
                    }
                  } else {
                    if (_currentSideIndex != index) {
                      _currentSideIndex = index;
                      _animateSelection();
                    }
                  }
                });
              },
              initialPage:
                  _selectedType == '主線' ? _currentMainIndex : _currentSideIndex,
              enableInfiniteScroll: false,
              autoPlay: false,
            ),
            itemBuilder: (context, index, realIndex) {
              final bool isSelected = index == currentIndex;

              return AnimatedScale(
                scale: isSelected && _isAnimating ? _selectedScale : 1.0,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(
                    vertical: isSelected ? 10 : 25,
                    horizontal: isSelected ? 0 : 10,
                  ),
                  decoration: BoxDecoration(
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: Colors.blue.withValues(
                                  alpha: _pulseEffect ? 0.7 : 0.4,
                                ),
                                blurRadius: _pulseEffect ? 20 : 15,
                                spreadRadius: _pulseEffect ? 4 : 2,
                              ),
                            ]
                            : [],
                  ),
                  child: ScenarioCard(
                    scenario: scenarios[index],
                    isSelected: isSelected,
                    pulseEffect: isSelected && _pulseEffect,
                  ),
                ),
              );
            },
          ),
        ),

        // 左右箭頭按鈕
        _buildNavigationArrows(),
      ],
    );
  }

  Widget _buildProgressIndicator(
    List<ScenarioData> scenarios,
    int currentIndex,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(scenarios.length, (index) {
        final bool isActive = currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isActive ? 6 : 6),
            color: isActive ? Colors.blue : Colors.grey.shade700,
            border: Border.all(color: Colors.white38, width: 1),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                    : [],
          ),
        );
      }),
    );
  }

  Widget _buildNavigationArrows() {
    final bool isMainTab = _selectedType == '主線';
    final int currentIndex = isMainTab ? _currentMainIndex : _currentSideIndex;
    final int scenarioCount =
        isMainTab ? _mainScenarios.length : _sideScenarios.length;
    final bool canGoPrevious = currentIndex > 0;
    final bool canGoNext = currentIndex < scenarioCount - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavigationArrow(
            icon: Icons.arrow_back_ios_rounded,
            enabled: canGoPrevious,
            onPressed: () {
              if (canGoPrevious) {
                if (isMainTab) {
                  _mainCarouselController.previousPage();
                } else {
                  _sideCarouselController.previousPage();
                }
              }
            },
          ),
          _buildNavigationArrow(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: canGoNext,
            onPressed: () {
              if (canGoNext) {
                if (isMainTab) {
                  _mainCarouselController.nextPage();
                } else {
                  _sideCarouselController.nextPage();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationArrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:
            enabled ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color:
              enabled
                  ? Colors.blue.withValues(alpha: 0.7)
                  : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey.shade700,
          size: 30,
        ),
        onPressed: enabled ? onPressed : null,
        splashColor: Colors.blue.withValues(alpha: 0.3),
        highlightColor: Colors.blue.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildStartButton() {
    ScenarioData selectedScenario =
        _selectedType == '主線'
            ? _mainScenarios[_currentMainIndex]
            : _sideScenarios[_currentSideIndex];

    final bool isLocked = selectedScenario.locked;

    return Hero(
      tag: 'start_button',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color:
                  isLocked
                      ? Colors.grey.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: _pulseEffect ? 0.7 : 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isLocked) {
                _showLockedScenarioDialog(context);
              } else {
                // 開始遊戲動畫效果
                _animateSelection();

                // 延遲一下再跳轉，讓動畫效果更明顯
                Future.delayed(const Duration(milliseconds: 300), () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              GameWidget(game: NightAndRainGame()),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                });
              }
            },
            borderRadius: BorderRadius.circular(30),
            splashFactory: InkRipple.splashFactory,
            splashColor: Colors.blue.withValues(alpha: 0.3),
            highlightColor: Colors.blue.withValues(alpha: 0.1),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isLocked
                          ? [Colors.grey.shade700, Colors.grey.shade800]
                          : [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isLocked ? Colors.grey : Colors.white70,
                  width: 2,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isLocked
                        ? const Icon(Icons.lock, color: Colors.white70)
                        : const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                    const SizedBox(width: 10),
                    Text(
                      isLocked ? '需要解鎖' : '開始遊戲',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLockedScenarioDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation1, animation2) => const SizedBox(),
      transitionBuilder: (context, a1, a2, child) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 0.05;
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10 * a1.value,
            sigmaY: 10 * a1.value,
          ),
          child: Transform.scale(
            scale: curvedValue < 0 ? 0 : curvedValue,
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                backgroundColor: Colors.blue.shade900.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.blue.shade300, width: 2),
                ),
                title: const Text(
                  '劇本鎖定中',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.7),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.amber,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '這個劇本目前尚未解鎖。\n請先完成前置劇情以解鎖此劇本！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.shade800.withValues(
                        alpha: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: const BorderSide(color: Colors.white30, width: 1),
                      ),
                    ),
                    child: const Text(
                      '返回',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ],
                actionsAlignment: MainAxisAlignment.center,
                buttonPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

// 背景粒子效果
class ParticleBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  ParticleBackgroundPainter({required this.animation})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.2)
          ..strokeCap = StrokeCap.round;

    final random = math.Random(42); // 固定種子使粒子分佈一致

    // 繪製50個漂浮的粒子
    for (int i = 0; i < 50; i++) {
      // 粒子基本位置
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // 粒子移動參數
      final speed = 0.8 + random.nextDouble() * 0.5;
      final amplitude = 5.0 + random.nextDouble() * 15.0;
      final frequency = 0.5 + random.nextDouble() * 1.5;

      // 動態位移計算
      final dx =
          amplitude * math.sin(animation.value * frequency * math.pi * 2 + i);
      final dy =
          speed * math.cos(animation.value * frequency * math.pi + i * 0.7) * 5;

      // 粒子大小
      final radius = 1.0 + random.nextDouble() * 2.0;

      // 畫粒子
      paint.color =
          HSLColor.fromAHSL(
            0.5 + random.nextDouble() * 0.5, // 透明度
            210 + random.nextDouble() * 40, // 藍色色調
            0.8, // 飽和度
            0.7 + random.nextDouble() * 0.3, // 亮度
          ).toColor();

      canvas.drawCircle(Offset(x + dx, y + dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
