import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:fruit_cutter_game/main.dart';

void main() {
  testWidgets('Game widget pumps successfully', (WidgetTester tester) async {
    // Build our game widget and trigger a frame.
    await tester.pumpWidget(
      GameWidget(
        game: FruitCutterGame(),
      ),
    );

    // Verify that our GameWidget exists in the tree.
    expect(find.byType(GameWidget<FruitCutterGame>), findsOneWidget);
  });
}
