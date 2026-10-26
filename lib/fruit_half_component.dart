import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'fruit_types.dart';

class FruitHalfComponent extends SpriteComponent with HasGameReference {
  final FruitType type;
  final bool isLeftHalf;
  Vector2 velocity;
  final double gravity = 550.0; 
  double angularVelocity;

  FruitHalfComponent({
    required this.type,
    required this.isLeftHalf,
    required Vector2 position,
    required this.velocity,
    required double initialAngle,
  }) : angularVelocity = isLeftHalf ? -4.0 : 4.0, // Clean spinning torque push
       super(
         position: position,
         size: Vector2(80, 80), // Aligned with the main 80x80 FruitComponent size
         anchor: Anchor.center,
         angle: initialAngle,
       );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Map types directly to your crisp 256x256 image assets
    String spriteName = '';
    switch (type) {
      case FruitType.watermelon:  spriteName = 'watermelon.png'; break;
      case FruitType.apple:       spriteName = 'apple.png'; break;
      case FruitType.banana:      spriteName = 'banana.png'; break;
      case FruitType.crystalkiwi:  spriteName = 'crystalkiwi.png'; break;
      case FruitType.dragonfruit: spriteName = 'dragonfruit.png'; break;
      case FruitType.bomb:        spriteName = 'bomb.png'; break;
    }

    sprite = await game.loadSprite(spriteName);
  }

  @override
  void update(double dt) {
    super.update(dt);
    velocity.y += gravity * dt;
    position += velocity * dt;
    angle += angularVelocity * dt;

    // Wipe object out of memory cleanly when it drops past the floor layout threshold
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // 1. Trap the drawing bounds to clip half of the texture layout
    canvas.save();

    // Clip half of our 80x80 size frame relative to our center anchor point
    final clipRect = isLeftHalf 
        ? Rect.fromLTWH(0, 0, size.x / 2, size.y)
        : Rect.fromLTWH(size.x / 2, 0, size.x / 2, size.y);
    canvas.clipRect(clipRect);

    // 2. Direct Flame to draw the clipped PNG texture into the captured path bounds
    super.render(canvas);
    
    canvas.restore();
  }
}
