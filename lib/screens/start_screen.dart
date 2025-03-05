import 'package:flutter/material.dart';
import 'select_theme_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _navigateToThemeScreen(BuildContext context, bool isTwoPlayer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectThemeScreen(isTwoPlayer: isTwoPlayer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A2E)], // Dark Cyberpunk Gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: child,
                  );
                },
                child: const Text(
                  "FLIPCARD",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: Colors.cyan, blurRadius: 15),
                      Shadow(color: Colors.blue, blurRadius: 25),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              _buildNeonButton(
                text: "1 Player Mode",
                color: Colors.blueAccent,
                onTap: () => _navigateToThemeScreen(context, false),
              ),
              const SizedBox(height: 20),
              _buildNeonButton(
                text: "2 Player Mode",
                color: Colors.purpleAccent,
                onTap: () => _navigateToThemeScreen(context, true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeonButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
