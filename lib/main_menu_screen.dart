import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'game_over_overlay.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load local sound preferences cleanly from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  // Toggle and save settings state dynamically
  Future<void> _toggleSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    setState(() {
      _isSoundEnabled = value;
    });
  }

  Future<int> _getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('best_score') ?? 0;
  }

  // Displays an elegant arcade settings dashboard overlay modal sheet
  void _showSettingsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF212121),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // Change lines 77 to 84 to look exactly like this:
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ), // This closing parenthesis ends the container arguments cleanly!
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings, color: Color(0xFFFFB300), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'GAME SETTINGS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  ListTile(
                    leading: Icon(
                      _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                      color: _isSoundEnabled
                          ? const Color(0xFF00E676)
                          : Colors.white24,
                    ),
                    title: const Text(
                      'Sound Effects',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Switch(
                      activeThumbColor: const Color(0xFF00E676),
                      value: _isSoundEnabled,
                      onChanged: (bool value) async {
                        await _toggleSound(value);
                        setModalState(
                          () {},
                        ); // Syncs toggle inside active modal window
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-Screen Photographic Kitchen Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/menu_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Soft Ambient Vignette Shading Layer
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Main Interface Layer
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // TOP NAVIGATION HUD ROW
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dynamic SharedPreferences Top High Score Banner Layout
                        FutureBuilder<int>(
                          future: _getHighScore(),
                          builder: (context, snapshot) {
                            final int currentBest = snapshot.data ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: const Color(0xFF00E676),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Color(0xFFFFB300),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'BEST: $currentBest',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // SETTINGS ICON GEAR BUTTON
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _showSettingsDialog,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Animated Breathing Title Block
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final double hoverOffsetY =
                          math.sin(_animationController.value * math.pi) * 8.0;
                      return Transform.translate(
                        offset: Offset(0, hoverOffsetY),
                        child: child,
                      );
                    },
                    child: const Column(
                      children: [
                        Text(
                          'FRUIT',
                          style: TextStyle(
                            fontSize: 66,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFEB3B),
                            letterSpacing: 6,
                            height: 0.9,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 12,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'CUTTER',
                          style: TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5722),
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                blurRadius: 12,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SUDDEN DEATH MODE',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // 4. Sleeker, Perfectly Fitted "SLICE TO PLAY" Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: screenSize.width * 0.72,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 14,
                            shadowColor: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  body: GameWidget<FruitCutterGame>(
                                    game: FruitCutterGame(),
                                    overlayBuilderMap: {
                                      'GameOverOverlay': (context, game) =>
                                          GameOverOverlay(game: game),
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'SLICE TO PLAY',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
