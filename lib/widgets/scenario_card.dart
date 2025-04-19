import 'package:flutter/material.dart';
import '../models/scenario_data.dart';

class ScenarioCard extends StatelessWidget {
  final ScenarioData scenario;
  final bool isSelected;
  final bool pulseEffect;

  const ScenarioCard({
    super.key,
    required this.scenario,
    this.isSelected = false,
    this.pulseEffect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 12 : 6,
      shadowColor: Colors.blue.withValues(alpha: isSelected ? 0.6 : 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _getBorderColor(),
          width: isSelected ? 3.0 : 2.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 劇本背景圖片
          Positioned.fill(child: _buildBackgroundImage()),

          // 鎖定狀態overlay
          if (scenario.locked) _buildLockedOverlay(),

          // 選中時發光特效
          if (isSelected && !scenario.locked) _buildGlowEffect(),

          // 劇本內容
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(),
                const SizedBox(height: 18),
                _buildDescription(),
                const SizedBox(height: 25),
                // 劇本資訊
                _buildInfoChips(),
              ],
            ),
          ),

          // 右上角選中標記
          if (isSelected && !scenario.locked) _buildSelectionIndicator(),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (scenario.locked) {
      return Colors.grey;
    } else if (isSelected) {
      return Colors.blue.shade300;
    } else {
      return Colors.blueAccent.withValues(alpha: 0.7);
    }
  }

  Widget _buildBackgroundImage() {
    return Hero(
      tag: 'scenario_bg_${scenario.id}',
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(
            alpha:
                scenario.locked
                    ? 0.8
                    : isSelected
                    ? 0.4
                    : 0.5,
          ),
          BlendMode.darken,
        ),
        child: Image.asset(scenario.thumbnail, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.lock,
            size: 60,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowEffect() {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent, width: 0),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: pulseEffect ? 0.3 : 0.1),
              blurRadius: pulseEffect ? 30 : 15,
              spreadRadius: pulseEffect ? 5 : 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: const [Colors.white, Colors.lightBlue, Colors.white],
          stops:
              isSelected && !scenario.locked
                  ? [0.0, 0.5, 1.0]
                  : [0.0, 0.0, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        scenario.title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: const Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return Expanded(
      child: Text(
        scenario.description,
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          shadows: const [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 難度
        _buildChip(
          icon: Icons.storm,
          label: '難度：${scenario.difficulty}',
          color: _getDifficultyColor(scenario.difficulty),
        ),
        // 時間
        _buildChip(
          icon: Icons.access_time,
          label: scenario.duration,
          color: Colors.blue.shade800,
        ),
      ],
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: isSelected ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isSelected ? 0.9 : 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.white30 : Colors.transparent,
          width: 1,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                : [],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(child: Icon(Icons.check, color: Colors.white, size: 18)),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '簡單':
        return Colors.green.shade700;
      case '中等':
        return Colors.orange.shade700;
      case '困難':
        return Colors.red.shade700;
      case '極難':
        return Colors.purple.shade700;
      default:
        return Colors.blue.shade700;
    }
  }
}
