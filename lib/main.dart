import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flame/timer.dart' as flame_timer;
import 'package:shared_preferences/shared_preferences.dart';

import 'swipe_point.dart';
import 'fruit_component.dart';
import 'fruit_half_component.dart';
import 'fruit_types.dart';
import 'main_menu_screen.dart';

import 'package:flame_audio/flame_audio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Preload sound files into audio cache memory
  await FlameAudio.audioCache.loadAll([
    'slice.mp3',
    'frenzy.mp3',
    'explosion.mp3',
  ]);

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainMenuScreen(),
    ),
  );
}

class FruitCutterGame extends FlameGame with PanDetector {
  final List<SwipePoint> _swipePoints = [];
  final Paint _bladePaint = Paint();
  late Sprite _backgroundSprite;
    bool isSoundEnabled = true;
  bool isGameInitialized =
      false; // Prevents update loops from running prematurely

  // Pre-allocated sound pools for instant simultaneous execution
  late AudioPool _slicePool;
  late AudioPool _explosionPool;

  final int _trailDurationMs = 250;
  final Random _random = Random();
  late flame_timer.Timer _spawnTimer;

  int score = 0;
  int highScore = 0;
  int revivesUsed = 0;
  final int maxRevives = 3;
  bool isGameOver = false;
  double _timeSinceLastBanana = 15.0;

  // New Mechanics States
  double _multiplierTimer = 0.0;
  bool get isDoublePoints => _multiplierTimer > 0.0;

  late TextComponent _scoreText;
  late TextComponent _highScoreText;
  late TextComponent _multiplierHUDText;

    @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Initialize instant-fire audio pools
    _slicePool = await FlameAudio.createPool(
      'slice.mp3',
      maxPlayers: 6,
    );
    _explosionPool = await FlameAudio.createPool(
      'explosion.mp3',
      maxPlayers: 2,
    );

    // 2. Load your background sprite asset safely
    _backgroundSprite = await loadSprite('background.png'); 

    // 3. Load settings and high score from storage disk
    final prefs = await SharedPreferences.getInstance();
    isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    await _loadHighScore();

    // 4. Fire up the layout component injectors
    _initGame(fullReset: true);

    // 5. Mark initialization complete so loops can execute
    isGameInitialized = true;
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('best_score') ?? 0;
  }

  Future<void> _saveHighScore(int newHigh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', newHigh);
  }

    void _playSound(String filename) {
    if (isSoundEnabled) {
      if (filename == 'slice.mp3') {
        _slicePool.start(); // Instant execution via pre-allocated channel
      } else if (filename == 'explosion.mp3') {
        _explosionPool.start();
      } else {
        FlameAudio.play(filename); // Fallback for single non-rapid sounds like frenzy.mp3
      }
    }
  }

  void _initGame({required bool fullReset}) {
    if (fullReset) {
      score = 0;
      revivesUsed = 0;
      _multiplierTimer = 0.0;
    }
    isGameOver = false;

    double spawnInterval = score > 30 ? 1.0 : 1.5;
    _spawnTimer = flame_timer.Timer(
      spawnInterval,
      onTick: _spawnFruitGroup,
      repeat: true,
    );

    // --- SLEEK SCORE PANEL ---
    _scoreText = TextComponent(
      text: 'Score: $score',
      position: Vector2(24, 44),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFEB3B), // Bright Golden Yellow
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 3)),
          ],
        ),
      ),
    );
    add(_scoreText);

    // --- SLEEK BEST SCORE PANEL ---
    _highScoreText = TextComponent(
      text: 'Best: $highScore',
      position: Vector2(size.x - 170, 44),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00E676), // Vibrant Neon Green
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 6, offset: Offset(2, 3)),
          ],
        ),
      ),
    );
    add(_highScoreText);

    // Multiplier Text HUD Setup
    _multiplierHUDText = TextComponent(
      text: '',
      position: Vector2(20, 80),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF00E676),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      ),
    );
    add(_multiplierHUDText);
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
    final int count = score > 25
        ? (_random.nextInt(3) + 1)
        : (_random.nextInt(2) + 1);

    for (int i = 0; i < count; i++) {
      _spawnSingleRandomItem();
    }
  }

  void _spawnSingleRandomItem({double speedModifier = 1.0}) {
    final bool spawnBomb = _random.nextDouble() < 0.20;

    final playableTypes = FruitType.values
        .where((t) => t != FruitType.bomb)
        .toList();
    FruitType type = spawnBomb
        ? FruitType.bomb
        : playableTypes[_random.nextInt(playableTypes.length)];

    if (type == FruitType.banana) {
      if (_timeSinceLastBanana < 15.0) {
        type = _random.nextBool() ? FruitType.apple : FruitType.watermelon;
      } else {
        _timeSinceLastBanana = 0.0;
      }
    }

    final xPosition = size.x * (0.2 + _random.nextDouble() * 0.6);
    final yPosition = size.y + 40;
    final double vx = ((_random.nextDouble() * 140) - 70) * speedModifier;
    final double vy = -(_random.nextDouble() * 150 + 680) * speedModifier;

    add(
      FruitComponent(
        fruitType: type,
        position: Vector2(xPosition, yPosition),
        initialVelocity: Vector2(vx, vy),
      ),
    );
  }

  void triggerBananaFrenzy() {
    _playSound('frenzy.mp3');
    int waveCount = 5;

    for (int i = 0; i < waveCount; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (!isGameOver) {
          _spawnSingleRandomItem(speedModifier: 0.85);
        }
      });
    }
  }

  @override
  void update(double dt) {
    // Safety guard to block the update cycle until components are constructed
    if (!isGameInitialized) return;

    super.update(dt);
    _spawnTimer.update(dt);
    _timeSinceLastBanana += dt;

    if (_multiplierTimer > 0.0) {
      _multiplierTimer -= dt;
      if (_multiplierTimer <= 0.0) {
        _multiplierHUDText.text = '';
      } else {
        _multiplierHUDText.text =
            '2X POINTS: ${_multiplierTimer.toStringAsFixed(1)}s';
      }
    }

    final now = DateTime.now();
    _swipePoints.removeWhere(
      (point) =>
          now.difference(point.timestamp).inMilliseconds > _trailDurationMs,
    );
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
    _swipePoints.add(
      SwipePoint(
        position: Offset(globalPosition.x, globalPosition.y),
        timestamp: DateTime.now(),
      ),
    );
  }

  void _checkCollisions() {
    if (_swipePoints.length < 2) return;
    final p1 = _swipePoints[_swipePoints.length - 2].position;
    final p2 = _swipePoints[_swipePoints.length - 1].position;
    final fruits = children.whereType<FruitComponent>().toList();

    for (final fruit in fruits) {
      final fruitCenter = Offset(fruit.position.x, fruit.position.y);
      double calculatedRadius = fruit.size.x / 2;
      if (_checkLineCircleIntersection(p1, p2, fruitCenter, calculatedRadius)) {
        _sliceFruit(fruit);
      }
    }
  }

  bool _checkLineCircleIntersection(
    Offset p1,
    Offset p2,
    Offset center,
    double radius,
  ) {
    final double l2 =
        (p1.dx - p2.dx) * (p1.dx - p2.dx) + (p1.dy - p2.dy) * (p1.dy - p2.dy);
    if (l2 == 0) return (p1 - center).distance <= radius;

    double t =
        ((center.dx - p1.dx) * (p2.dx - p1.dx) +
            (center.dy - p1.dy) * (p2.dy - p1.dy)) /
        l2;
    t = t.clamp(0.0, 1.0);
    final Offset projection = Offset(
      p1.dx + t * (p2.dx - p1.dx),
      p1.dy + t * (p2.dy - p1.dy),
    );
    return (projection - center).distance <= radius;
  }

  void _sliceFruit(FruitComponent fruit) {
    fruit.removeFromParent();

    if (fruit.fruitType == FruitType.bomb) {
      _playSound('explosion.mp3');
      triggerGameOver();
      return;
    }
    _playSound('slice.mp3');

    if (fruit.fruitType == FruitType.banana) {
      triggerBananaFrenzy();
    } else if (fruit.fruitType == FruitType.crystalkiwi) {
      _multiplierTimer = 5.0;
    }

    int basePoints = fruit.pointsValue;
    if (basePoints == 0) basePoints = 1;

    score += isDoublePoints ? (basePoints * 2) : basePoints;

    if (score > highScore) {
      highScore = score;
      _highScoreText.text = 'Best: $highScore';
      _saveHighScore(highScore);
    }
    _scoreText.text = 'Score: $score';
    add(
      FruitHalfComponent(
        type: fruit.fruitType,
        isLeftHalf: true,
        position: fruit.position.clone(),
        velocity: Vector2(fruit.velocity.x - 120, fruit.velocity.y * 0.7),
        initialAngle: fruit.angle,
      ),
    );
    add(
      FruitHalfComponent(
        type: fruit.fruitType,
        isLeftHalf: false,
        position: fruit.position.clone(),
        velocity: Vector2(fruit.velocity.x + 120, fruit.velocity.y * 0.7),
        initialAngle: fruit.angle,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Safety guard to prevent rendering background assets before initialization complete
    if (!isGameInitialized) return;
    _backgroundSprite.render(canvas, position: Vector2.zero(), size: size);
    super.render(canvas);
    if (!isGameOver && _swipePoints.length > 1) {
      final now = DateTime.now();
      for (int i = 0; i < _swipePoints.length - 1; i++) {
        final p1 = _swipePoints[i];
        final p2 = _swipePoints[i + 1];
        final ageMs = now.difference(p1.timestamp).inMilliseconds;
        final lifeRatio = 1.0 - (ageMs / _trailDurationMs).clamp(0.0, 1.0);
        _bladePaint.strokeWidth = 2.0 + (6.0 * lifeRatio);
        _bladePaint.color = const Color(0xFFE0F7FA)
            .withValues(alpha: lifeRatio);
        canvas.drawLine(p1.position, p2.position, _bladePaint);
      }
    }
  }
}
