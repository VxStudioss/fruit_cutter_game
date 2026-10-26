import 'package:flame/components.dart';
import 'fruit_types.dart'; // Or '../fruit_types.dart' depending on your exact folder layout

class FruitComponent extends SpriteComponent with HasGameReference {
  final FruitType fruitType;
  Vector2 velocity = Vector2.zero();
  
    int get pointsValue {
    switch (fruitType) {
      case FruitType.apple:
      case FruitType.watermelon:
        return 1;
      case FruitType.dragonfruit:
        return 5;
      case FruitType.bomb:
        return 0; // Handled separately as an explosion game-over event
      default:
        return 0; // Special item logic (banana/kiwi) handles points dynamically
    }
  }

  FruitComponent({
    required this.fruitType,
    required Vector2 position,
    required Vector2 initialVelocity,
  }) : super(
          position: position,
          size: Vector2(80, 80), 
          anchor: Anchor.center,
        ) {
    velocity = initialVelocity;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    String spriteName = '';
    switch (fruitType) {
      case FruitType.apple:       spriteName = 'apple.png'; break;
      case FruitType.watermelon:  spriteName = 'watermelon.png'; break;
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
    
    velocity.y += 400 * dt; 
    position += velocity * dt;
    angle += 2 * dt; 

    if (position.y > game.size.y + 100) {
      removeFromParent();
    }
  }

  void slice() {
    removeFromParent(); 
    
    if (fruitType == FruitType.bomb) {
      // Game over logic
    } else if (fruitType == FruitType.banana) {
      // Trigger Frenzy Mode
    } else if (fruitType == FruitType.crystalkiwi) {
      // Trigger x2 Multiplier
    }
  }
}
