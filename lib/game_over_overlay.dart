import 'package:flutter/material.dart';
import 'main.dart';

class GameOverOverlay extends StatelessWidget {
  final FruitCutterGame game;
  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Check if the player still has remaining ad revives available
    final bool canRevive = game.revivesUsed < game.maxRevives;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title displaying the end-game condition
              const Text(
                'GAME OVER',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFFE53935), letterSpacing: 3),
              ),
              const SizedBox(height: 8),
              
              // Final score display
              Text(
                'Score: ${game.score}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFFFD54F)),
              ),
              const SizedBox(height: 40),

              // --- PREMIUM REVIVE AND CONTINUE AD BUTTON ---
              GestureDetector(
                onTap: () {
                  if (canRevive) {
                    // Instantly resumes game loop from the exact current score point!
                    game.reviveAndContinueScore();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maximum revives reached for this run!')),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    // Changes color visually to indicate state changes
                    color: canRevive ? const Color(0xFF424E3F) : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded, 
                        color: canRevive ? Colors.white : Colors.white24, 
                        size: 24
                      ),
                      const SizedBox(width: 12),
                      Text(
                        canRevive 
                            ? 'Revive & Continue (${game.maxRevives - game.revivesUsed} Left)' 
                            : 'No Revives Remaining',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          color: canRevive ? Colors.white : Colors.white24
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- MAIN MENU TEXT LINK ---
              GestureDetector(
                onTap: () {
                  game.overlays.remove('GameOverOverlay');
                  Navigator.of(context).pop(); // Navigates out of the flame canvas back to menu root
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Main Menu',
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
