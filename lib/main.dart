import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flame/timer.dart' as flame_timer; 
import 'package:shared_preferences/shared_preferences.dart'; // Import local storage package
import 'swipe_point.dart';
import 'fruit_component.dart';
import 'fruit_half_component.dart';
import 'fruit_types.dart';
import 'main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainMenuScreen(),
    ),
  );
}

class FruitCutterGame extends FlameGame with PanDetector {
  final List<SwipePoint> _swipePoints = [];
  final Paint _bladePaint = Paint()
    ..color = const Color(0xFFE0F7FA)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final int _trailDurationMs = 250;
  final Random _random = Random();
  late flame_timer.Timer _spawnTimer;

  int score = 0;
  int highScore = 0;
  int revivesUsed = 0; 
  final int maxRevives = 3; 
  bool isGameOver = false;
  
  late TextComponent _scoreText;
  late TextComponent _highScoreText;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 1. Load the permanently saved high score first before drawing the game
    await _loadHighScore();
    _initGame(fullReset: true);
  }

  /// Reads the device storage to retrieve the historical best score
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve the integer value stored under the key 'best_score' (defaults to 0 if empty)
    highScore = prefs.getInt('best_score') ?? 0;
  }

  /// Writes a new personal best score securely onto local device memory
  Future<void> _saveHighScore(int newHigh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', newHigh);
  }

  void _initGame({required bool fullReset}) {
    if (fullReset) {
      score = 0;
      revivesUsed = 0;
    }
    isGameOver = false;

    double spawnInterval = score > 30 ? 1.0 : 1.5;
    _spawnTimer = flame_timer.Timer(spawnInterval, onTick: _spawnFruitGroup, repeat: true);

    _scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(20, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFEB3B),
          fontSize: 26,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
        ),
      ),
    );
    add(_scoreText);

    _highScoreText = TextComponent(
      text: 'Best: $highScore',
      position: Vector2(size.x - 140, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF5722),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
        ),
      ),
    );
    add(_highScoreText);
  }

  void triggerGameOver() {
    if (isGameOver) return;
    isGameOver = true;
    _spawnTimer.stop();
    children.whereType<FruitComponent>().forEach((f) => f.removeFromParent());
    overlays.add('GameOverOverlay');
  }

  void resetGame() {
    overlays.remove('GameOverOverlay');
    removeAll(children); 
    _initGame(fullReset: true);
  }

  void reviveAndContinueScore() {
    if (revivesUsed >= maxRevives) return;
    revivesUsed++;
    overlays.remove('GameOverOverlay');
    removeAll(children); 
    _initGame(fullReset: false); 
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      _highScoreText.position = Vector2(size.x - 140, 40);
    }
  }

  void _spawnFruitGroup() {
    if (isGameOver) return;
    final int count = score > 25 ? (_random.nextInt(3) + 1) : (_random.nextInt(2) + 1);
    
    for (int i = 0; i < count; i++) {
      final bool spawnBomb = _random.nextDouble() < 0.20;
      final type = spawnBomb ? FruitType.bomb : FruitType.values[_random.nextInt(FruitType.values.length - 1)];

      final xPosition = size.x * (0.2 + _random.nextDouble() * 0.6);
      final yPosition = size.y + 40;
      final double vx = (_random.nextDouble() * 140) - 70;
      final double vy = -(_random.nextDouble() * 150 + 680); 

      add(FruitComponent(type: type, position: Vector2(xPosition, yPosition), velocity: Vector2(vx, vy)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _spawnTimer.update(dt);
    
    final now = DateTime.now();
    _swipePoints.removeWhere((point) => now.difference(point.timestamp).inMilliseconds > _trailDurationMs);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (isGameOver) return;
    _swipePoints.clear();
    _addPoint(info.eventPosition.global);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver) return;
    _addPoint(info.eventPosition.global);
    _checkCollisions();
  }

  void _addPoint(Vector2 globalPosition) {
    _swipePoints.add(SwipePoint(position: Offset(globalPosition.x, globalPosition.y), timestamp: DateTime.now()));
  }

  void _checkCollisions() {
    if (_swipePoints.length < 2) return;
    final p1 = _swipePoints[_swipePoints.length - 2].position;
    final p2 = _swipePoints[_swipePoints.length - 1].position;
    final fruits = children.whereType<FruitComponent>().toList();

    for (final fruit in fruits) {
      final fruitCenter = Offset(fruit.position.x, fruit.position.y);
      if (_checkLineCircleIntersection(p1, p2, fruitCenter, fruit.radius)) {
        _sliceFruit(fruit);
      }
    }
  }

  bool _checkLineCircleIntersection(Offset p1, Offset p2, Offset center, double radius) {
    final double l2 = (p1.dx - p2.dx) * (p1.dx - p2.dx) + (p1.dy - p2.dy) * (p1.dy - p2.dy);
    if (l2 == 0) return (p1 - center).distance <= radius;

    double t = ((center.dx - p1.dx) * (p2.dx - p1.dx) + (center.dy - p1.dy) * (p2.dy - p1.dy)) / l2;
    t = t.clamp(0.0, 1.0);
    final Offset projection = Offset(p1.dx + t * (p2.dx - p1.dx), p1.dy + t * (p2.dy - p1.dy));
    return (projection - center).distance <= radius;
  }

  void _sliceFruit(FruitComponent fruit) {
    fruit.removeFromParent();

    if (fruit.type == FruitType.bomb) {
      triggerGameOver();
      return;
    }

    score += 1;
    // FIXED: Save the score to device storage immediately when breaking a high score
    if (score > highScore) {
      highScore = score;
      _highScoreText.text = 'Best: $highScore';
      _saveHighScore(highScore); // Fire storage save routine
    }
    _scoreText.text = 'Score: $score';

    add(FruitHalfComponent(
      type: fruit.type,
      isLeftHalf: true,
      position: fruit.position.clone(),
      velocity: Vector2(fruit.velocity.x - 100, fruit.velocity.y * 0.7),
      initialAngle: fruit.angle,
    ));

    add(FruitHalfComponent(
      type: fruit.type,
      isLeftHalf: false,
      position: fruit.position.clone(),
      velocity: Vector2(fruit.velocity.x + 100, fruit.velocity.y * 0.7),
      initialAngle: fruit.angle,
    ));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawColor(const Color(0xFF3E2723), BlendMode.src);
    super.render(canvas);

    if (!isGameOver && _swipePoints.length > 1) {
      final now = DateTime.now();
      for (int i = 0; i < _swipePoints.length - 1; i++) {
        final p1 = _swipePoints[i];
        final p2 = _swipePoints[i + 1];
        final ageMs = now.difference(p1.timestamp).inMilliseconds;
        final lifeRatio = 1.0 - (ageMs / _trailDurationMs).clamp(0.0, 1.0);

        _bladePaint.strokeWidth = 2.0 + (6.0 * lifeRatio);
        _bladePaint.color = const Color(0xFFE0F7FA).withValues(alpha: lifeRatio);
        canvas.drawLine(p1.position, p2.position, _bladePaint);
      }
    }
  }
}
