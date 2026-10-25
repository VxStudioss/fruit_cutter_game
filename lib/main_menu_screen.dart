import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'main.dart';
import 'game_over_overlay.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5D4037), Color(0xFF3E2723)], 
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FRUIT',
              // FIXED: Swapped out 'FontWeight.black' with 'FontWeight.w900'
              style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFFFFEB3B), letterSpacing: 4, height: 0.9),
            ),
            const Text(
              'CUTTER',
              style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Color(0xFFFF5722), letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            const Text(
              'SUDDEN DEATH MODE',
              style: TextStyle(fontSize: 16, color: Colors.white60, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
            const SizedBox(height: 60),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
                shadowColor: Colors.black,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: GameWidget<FruitCutterGame>(
                        game: FruitCutterGame(),
                        overlayBuilderMap: {
                          'GameOverOverlay': (context, game) => GameOverOverlay(game: game),
                        },
                      ),
                    ),
                  ),
                );
              },
              child: const Text(
                'SLICE TO PLAY',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
