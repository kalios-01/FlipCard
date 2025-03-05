import 'dart:async';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../widgets/memory_card.dart';
import '../utils/game_logic.dart';
import '../utils/neonseekbar.dart';


class GameScreen extends StatefulWidget {
  final bool isTwoPlayer;
  final String theme;

  const GameScreen({super.key, required this.isTwoPlayer, required this.theme});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<CardModel> _cards;
  CardModel? _firstCard;
  CardModel? _secondCard;
  bool _isProcessing = false;

  int _player1Score = 0;
  int _player2Score = 0;
  bool _isPlayer1Turn = true;
  int _timeLeft = 90;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _player1Score = 0;
    _player2Score = 0;
    _isPlayer1Turn = true;
    _timeLeft = 90;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now we can safely use MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;
    _initializeGame(screenWidth);
  }

  void _initializeGame(double screenWidth) {
    setState(() {
      _cards = GameLogic().getShuffledCards(widget.theme, screenWidth);
      _firstCard = null;
      _secondCard = null;
      _isProcessing = false;
      if (!widget.isTwoPlayer) {
        _player1Score = 0; // Reset score
        _timeLeft = 90;   // Reset time
        _startTimer();     // Restart timer
      } else {
        _player1Score = 0;  // Reset player 1 score
        _player2Score = 0;  // Reset player 2 score
        _isPlayer1Turn = true; // Reset turn to player 1
      }
    });
  }

  void _startTimer() {
    _timer?.cancel(); // Cancel the existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _showGameOver();
      }
    });
  }

  void _flipCard(CardModel card) {
    if (_isProcessing || card.isFlipped || card.isMatched) return;

    setState(() {
      card.isFlipped = true;
      if (_firstCard == null) {
        _firstCard = card;
      } else {
        _secondCard = card;
        _isProcessing = true;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        if (_firstCard!.imagePath == _secondCard!.imagePath) {
          _firstCard!.isMatched = true;
          _secondCard!.isMatched = true;

          if (widget.isTwoPlayer) {
            _isPlayer1Turn ? _player1Score++ : _player2Score++;
          } else {
            _player1Score++;
          }
        } else {
          _firstCard!.isFlipped = false;
          _secondCard!.isFlipped = false;
          if (widget.isTwoPlayer) _isPlayer1Turn = !_isPlayer1Turn;
        }

        _firstCard = null;
        _secondCard = null;
        _isProcessing = false;
      });

      if (_cards.every((card) => card.isMatched)) {
        _timer?.cancel();
        _showGameOver();
      }
    });
  }

  void _showGameOver() {
    String message;
    Color glowColor;

    if (widget.isTwoPlayer) {
      if (_player1Score > _player2Score) {
        message = "Player 1 Wins!";
        glowColor = Colors.redAccent;
      } else if (_player2Score > _player1Score) {
        message = "Player 2 Wins!";
        glowColor = Colors.greenAccent;
      } else {
        message = "It's a Tie!";
        glowColor = Colors.cyanAccent;
      }
    } else {
      message = "Your Score: $_player1Score";
      glowColor = Colors.cyanAccent;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents tapping outside to close
      builder: (_) => WillPopScope(
        onWillPop: () async => false, // Prevents back button from closing the dialog
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: glowColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.7),
                  spreadRadius: 5,
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Game Over" text with glowing effect
                Text(
                  "Game Over",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: glowColor,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(blurRadius: 20, color: glowColor),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Winner / Score message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () {
                        Navigator.pop(context);
                        double screenWidth = MediaQuery.of(context).size.width;
                        _initializeGame(screenWidth);
                  },
                  child: _buildButton(
                    Colors.blueAccent, // Always show button in active color
                    "Play Again",
                  ),
                ),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () {
                        setState(() {
                          _timeLeft += 20;
                        });
                        Navigator.pop(context);
                        _startTimer();
                      },
                  child: _buildButton(
                    Colors.orangeAccent, // Always keep button clickable
                    "+20 sec",
                    icon: Icons.access_time,
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper function to create glowing buttons
  Widget _buildButton(Color color, String text, {IconData? icon}) {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.9),
              blurRadius: 15,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: Colors.black),
            if (icon != null) const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildScoreDisplay({required String imagePath, required int score, required Color glowColor, required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glowColor, width: isActive ? 3 : 1.5),
        boxShadow: isActive
            ? [
          BoxShadow(color: glowColor.withOpacity(0.8), blurRadius: 10, spreadRadius: 2),
        ]
            : [],
      ),
      child: Row(
        children: [
          Image.asset(imagePath, width: 28, height: 28),
          const SizedBox(width: 8),
          Text(
            ": $score",
            style: TextStyle(
              fontSize: 22,
              color: glowColor,
              fontWeight: FontWeight.bold,
              fontFamily: "Orbitron",
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),



        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 40, left: 12, right: 12, bottom: 8), // Smaller padding
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Timer with animated glow effect
                      if (!widget.isTwoPlayer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Smaller padding
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10), // Smaller border radius
                            border: Border.all(
                              color: _timeLeft > 60
                                  ? Colors.greenAccent
                                  : _timeLeft > 40
                                  ? Colors.yellowAccent
                                  : Colors.redAccent,
                              width: 1.5, // Thinner border
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_timeLeft > 60
                                    ? Colors.greenAccent
                                    : _timeLeft > 40
                                    ? Colors.yellowAccent
                                    : Colors.redAccent)
                                    .withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, color: Colors.white, size: 22), // Smaller icon
                              const SizedBox(width: 6), // Reduce spacing
                              Text(
                                " $_timeLeft",
                                style: TextStyle(
                                  fontSize: 18, // Smaller font
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Orbitron",
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Player 1 Score with glowing effect
                      _buildScoreDisplay(
                        imagePath: "assets/gamescreen/Player1.png",
                        score: _player1Score,
                        glowColor: Colors.redAccent,
                        isActive: _isPlayer1Turn,
                      ),

                      if (widget.isTwoPlayer)
                      // Player 2 Score with glowing effect
                        _buildScoreDisplay(
                          imagePath: "assets/gamescreen/Player2.png",
                          score: _player2Score,
                          glowColor: Colors.greenAccent,
                          isActive: !_isPlayer1Turn,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Neon Seek Bar (Shrinks from Right to Left)
            if (!widget.isTwoPlayer)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Align(
                  alignment: Alignment.centerLeft, // Align it to the left
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft, // Keep the start fixed at left
                    widthFactor: _timeLeft / 90, // Shrinks from right to left
                    child: NeonSeekBar(
                      progress: 1, // Always full internally
                      glowColor: _timeLeft > 60
                          ? Colors.greenAccent
                          : _timeLeft > 40
                          ? Colors.yellowAccent
                          : Colors.redAccent,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (_, index) => MemoryCard(
                  card: _cards[index],
                  onTap: () => _flipCard(_cards[index]),
                  theme: widget.theme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}