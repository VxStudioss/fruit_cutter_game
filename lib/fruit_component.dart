import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'fruit_types.dart';

class FruitComponent extends PositionComponent with HasGameReference {
  final FruitType type;
  
  Vector2 velocity;
  final double gravity = 450.0; 
  double angularVelocity; 

  final double radius;

  FruitComponent({
    required this.type,
    required Vector2 position,
    required this.velocity,
    this.radius = 28.0,
  }) : angularVelocity = (Random().nextDouble() * 4) - 2,
       super(
         position: position,
         size: Vector2.all(28.0 * 2),
         anchor: Anchor.center,
       );

    @override
  void update(double dt) {
    super.update(dt);
    
    velocity.y += gravity * dt;
    position += velocity * dt;
    angle += angularVelocity * dt;

    // When a fruit falls past the bottom edge
    if (position.y > game.size.y + size.y) {
      removeFromParent(); // Despawn it cleanly from memory
      
      // REMOVED: The instant sudden death trigger for dropped fruits is gone!
      // Missing a fruit is now safe. Slicing a bomb is the only way to lose.
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    switch (type) {
      case FruitType.watermelon:
        paint.color = const Color(0xFF2E7D32);
        canvas.drawCircle(Offset.zero, radius, paint);
        paint.color = const Color(0xFF81C784);
        canvas.drawCircle(Offset.zero, radius - 3, paint);
        paint.color = const Color(0xFFE91E63);
        canvas.drawCircle(Offset.zero, radius - 6, paint);
        paint.color = Colors.black87;
        canvas.drawCircle(const Offset(-6, -4), 1.5, paint);
        canvas.drawCircle(const Offset(6, -4), 1.5, paint);
        canvas.drawCircle(const Offset(0, 6), 1.5, paint);
        break;

      case FruitType.orange:
        paint.color = const Color(0xFFEF6C00);
        canvas.drawCircle(Offset.zero, radius, paint);
        paint.color = const Color(0xFFFFE0B2);
        canvas.drawCircle(Offset.zero, radius - 3, paint);
        paint.color = const Color(0xFFFF9800);
        canvas.drawCircle(Offset.zero, radius - 5, paint);
        paint.color = const Color(0xFFFFE0B2);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.2;
        for (int i = 0; i < 8; i++) {
          final radians = (i * pi) / 4;
          canvas.drawLine(
            Offset.zero,
            Offset(cos(radians) * (radius - 5), sin(radians) * (radius - 5)),
            paint,
          );
        }
        break;

      case FruitType.apple:
        paint.color = const Color(0xFFC62828);
        canvas.drawCircle(Offset.zero, radius, paint);
        paint.color = const Color(0xFFFFCDD2);
        canvas.drawCircle(Offset(-8, -8), 4, paint);
        paint.color = const Color(0xFF5D4037);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2.5;
        canvas.drawLine(Offset.zero, const Offset(0, -32), paint);
        break;

      case FruitType.bomb:
        // FIXED: Explicitly handle bomb type rendering
        paint.color = const Color(0xFF212121);
        canvas.drawCircle(Offset.zero, radius, paint);
        paint.color = const Color(0xFFFF5722);
        canvas.drawCircle(Offset.zero, 6, paint);
        paint.color = const Color(0xFF757575);
        canvas.drawRect(Rect.fromCenter(center: const Offset(0, -20), width: 8, height: 8), paint);
        break;
    }

    canvas.restore();
  }
}
