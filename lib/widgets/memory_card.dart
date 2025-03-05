import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/theme_config.dart';

class MemoryCard extends StatefulWidget {
  final CardModel card;
  final VoidCallback onTap;
  final String theme; // Ensure theme is a String or appropriate type

  const MemoryCard({super.key, required this.card, required this.onTap, required this.theme});

  @override
  _MemoryCardState createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didUpdateWidget(MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.card.isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isFront = _flipAnimation.value < 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(_flipAnimation.value * 3.1416), // Card flip effect
            child: Container(
              width: MediaQuery.of(context).size.width * 0.2, // Adjusted width
              height: MediaQuery.of(context).size.width * 0.3, // Adjusted height for rectangular shape
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16), // More rounded corners
                border: Border.all(color: Colors.white, width: 1),
                image: DecorationImage(
                  image: AssetImage(
                    isFront
                        ? ThemeConfig.getCardFront(widget.theme) // Get front based on theme
                        : widget.card.imagePath, // Card back (image path)
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
