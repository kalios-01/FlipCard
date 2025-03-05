import 'package:flutter/material.dart';

class NeonSeekBar extends StatelessWidget {
  final double progress; // Value between 0 and 1
  final Color glowColor;

  const NeonSeekBar({super.key, required this.progress, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.black,
        border: Border.all(color: glowColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.7),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds:90 ),
            width: progress * MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [glowColor.withOpacity(0.8), glowColor.withOpacity(0.3)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}
