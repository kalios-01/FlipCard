import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_model.dart';
import '../utils/AdHelper.dart';
import '../utils/game_logic.dart';
import '../utils/neonseekbar.dart';
import '../utils/game_state_manager.dart';
import '../widgets/memory_card.dart';

class GameScreen extends StatefulWidget {
  final bool isTwoPlayer;
  final String theme;

  const GameScreen({super.key, required this.isTwoPlayer, required this.theme});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final adHelper = AdHelper();
  final gameStateManager = GameStateManager();

  late List<CardModel> _cards;
  CardModel? _firstCard;
  CardModel? _secondCard;
  bool _isProcessing = false;

  int _player1Score = 0;
  int _player2Score = 0;
  bool _isPlayer1Turn = true;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isGamePaused = false; // Track if game is paused but not reset

  @override
  void initState() {
    super.initState();
    _player1Score = 0;
    _player2Score = 0;
    _isPlayer1Turn = true;
    _timeLeft = 60;
    adHelper.preloadAds();
    
    // Initialize cards with a placeholder until we can get the screen width
    _cards = [];
    
    // Initialize cards and load saved game state
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Now we can safely use MediaQuery
      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;
      
      // Initialize cards if they haven't been initialized yet
      if (_cards.isEmpty) {
        _cards = GameLogic().getShuffledCards(widget.theme, screenWidth, screenHeight);
        print('Cards initialized in initState');
      }
      
      print('Initializing game, checking for saved state in GameStateManager');
      
      // First check if we have saved state in GameStateManager (highest priority)
      if (gameStateManager.isAddingTime && gameStateManager.hasSavedState()) {
        print('Found saved state in GameStateManager, restoring');
        _restoreGameStateFromManager();
      } 
      // Then check if we have saved state in SharedPreferences
      else {
        final bool loaded = await _loadGameState();
        if (loaded) {
          print('Loaded saved game state from SharedPreferences');
          setState(() {
            _isGamePaused = false;
          });
          
          // If we have a timer and it's not a two-player game, restart it
          if (!widget.isTwoPlayer) {
            _startTimer();
          }
        } else {
          // If no saved state, initialize the game
          print('No saved state found, initializing new game');
          _initializeGame(screenWidth, screenHeight);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // We're now initializing cards in initState, so we don't need to do it here
    // This method is kept for potential future use
  }

  void _initializeGame(double screenWidth, double screenHeight) {
    // If game is paused (adding time), don't reset the game state
    if (_isGamePaused) {
      return;
    }
    
    // Clear any saved state
    _clearGameState();
    
    setState(() {
      _cards = GameLogic().getShuffledCards(widget.theme, screenWidth, screenHeight);
      _firstCard = null;
      _secondCard = null;
      _isProcessing = false;
      if (!widget.isTwoPlayer) {
        _player1Score = 0; // Reset score
        _timeLeft = 60; // Reset time
        _startTimer(); // Restart timer
      } else {
        _player1Score = 0; // Reset player 1 score
        _player2Score = 0; // Reset player 2 score
        _isPlayer1Turn = true; // Reset turn to player 1
      }
    });
  }

  void _startTimer() {
    // Cancel any existing timer first
    _timer?.cancel();
    
    // Create a new timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
        
        // Save game state every 10 seconds
        if (_timeLeft % 10 == 0) {
          _saveGameState();
          
          // Also save to GameStateManager
          gameStateManager.saveGameState(
            cards: _cards,
            firstCard: _firstCard,
            secondCard: _secondCard,
            timeLeft: _timeLeft,
            isProcessing: _isProcessing,
            player1Score: _player1Score,
            player2Score: _player2Score,
            isPlayer1Turn: _isPlayer1Turn,
            isGamePaused: _isGamePaused,
            theme: widget.theme,
            isTwoPlayer: widget.isTwoPlayer,
          );
        }
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
          
          // Save game state after a successful match
          _saveGameState();
          
          // Also save to GameStateManager
          gameStateManager.saveGameState(
            cards: _cards,
            firstCard: _firstCard,
            secondCard: _secondCard,
            timeLeft: _timeLeft,
            isProcessing: _isProcessing,
            player1Score: _player1Score,
            player2Score: _player2Score,
            isPlayer1Turn: _isPlayer1Turn,
            isGamePaused: _isGamePaused,
            theme: widget.theme,
            isTwoPlayer: widget.isTwoPlayer,
          );
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

  void _addTimeAndContinue() async {
    // Clear the adding time flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAddingTime');
    
    setState(() {
      _timeLeft += 20; // Add 20 seconds
      _isGamePaused = false; // Mark game as resumed
      
      // If we have flipped cards that aren't matched, we need to continue processing them
      if (_firstCard != null && _secondCard != null && !_isProcessing) {
        _isProcessing = true;
        Future.delayed(Duration(milliseconds: 100), () {
          _checkMatch();
        });
      }
    });
    
    // Save the updated state
    await _saveGameState();
    
    // Restart the timer to continue the game
    _startTimer();
    
    print('Added 20 seconds, time left: $_timeLeft');
  }

  // Save game state to local storage
  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert cards to a list of maps with detailed information
    final List<Map<String, dynamic>> cardsData = _cards.map((card) {
      return {
        'imagePath': card.imagePath,
        'isFlipped': card.isFlipped,
        'isMatched': card.isMatched,
      };
    }).toList();
    
    // Save all game state
    await prefs.setString('cards', jsonEncode(cardsData));
    await prefs.setInt('player1Score', _player1Score);
    await prefs.setInt('player2Score', _player2Score);
    await prefs.setBool('isPlayer1Turn', _isPlayer1Turn);
    await prefs.setInt('timeLeft', _timeLeft);
    await prefs.setBool('isTwoPlayer', widget.isTwoPlayer);
    await prefs.setString('theme', widget.theme);
    await prefs.setBool('isGamePaused', _isGamePaused);
    await prefs.setBool('isProcessing', _isProcessing);
    
    // Save indices of first and second card if they exist
    if (_firstCard != null) {
      final int firstCardIndex = _cards.indexOf(_firstCard!);
      if (firstCardIndex >= 0) {
        await prefs.setInt('firstCardIndex', firstCardIndex);
      }
    } else {
      await prefs.remove('firstCardIndex');
    }
    
    if (_secondCard != null) {
      final int secondCardIndex = _cards.indexOf(_secondCard!);
      if (secondCardIndex >= 0) {
        await prefs.setInt('secondCardIndex', secondCardIndex);
      }
    } else {
      await prefs.remove('secondCardIndex');
    }
    
    // Save a timestamp to know when the state was saved
    await prefs.setInt('lastSaveTime', DateTime.now().millisecondsSinceEpoch);
    
    print('Game state saved successfully');
  }
  
  // Load game state from local storage
  Future<bool> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we have saved state
    if (!prefs.containsKey('cards')) {
      print('No saved cards found in SharedPreferences');
      return false;
    }
    
    try {
      // Check if the theme matches
      final String? savedTheme = prefs.getString('theme');
      final bool? savedIsTwoPlayer = prefs.getBool('isTwoPlayer');
      
      // If theme or game mode doesn't match, we can't restore
      if (savedTheme != widget.theme || savedIsTwoPlayer != widget.isTwoPlayer) {
        print('Theme or game mode mismatch');
        return false;
      }
      
      // Make sure we have cards initialized
      if (_cards.isEmpty) {
        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;
        
        // Get the optimal grid size
        final gridSize = GameLogic().calculateOptimalGrid(screenWidth, screenHeight);
        final int rows = gridSize['rows']!;
        final int columns = gridSize['columns']!;
        
        _cards = GameLogic().getShuffledCards(widget.theme, screenWidth, screenHeight);
        print('Cards initialized in _loadGameState');
      }
      
      // Load cards
      final String? cardsJson = prefs.getString('cards');
      if (cardsJson != null) {
        final List<dynamic> cardsData = jsonDecode(cardsJson);
        
        // Check if the saved card count matches our current grid
        if (cardsData.length != _cards.length) {
          print('Card count mismatch: saved ${cardsData.length}, current ${_cards.length}');
          
          // If the counts don't match, we need to adapt the saved state to our current grid
          // This is a complex operation and might result in a suboptimal experience
          // For simplicity, we'll just return false and let the game initialize a new state
          return false;
        }
        
        // Create new cards with the saved state
        final List<CardModel> newCards = [];
        
        for (int i = 0; i < cardsData.length; i++) {
          newCards.add(CardModel(
            imagePath: cardsData[i]['imagePath'],
            isFlipped: cardsData[i]['isFlipped'],
            isMatched: cardsData[i]['isMatched'],
          ));
        }
        
        // Load other game state
        _player1Score = prefs.getInt('player1Score') ?? 0;
        _player2Score = prefs.getInt('player2Score') ?? 0;
        _isPlayer1Turn = prefs.getBool('isPlayer1Turn') ?? true;
        _timeLeft = prefs.getInt('timeLeft') ?? 60;
        _isGamePaused = prefs.getBool('isGamePaused') ?? false;
        _isProcessing = prefs.getBool('isProcessing') ?? false;
        
        // Update the cards in the state
        setState(() {
          _cards = newCards;
          
          // Reset first and second card references
          _firstCard = null;
          _secondCard = null;
          
          // Restore first and second card references if they exist
          final int? firstCardIndex = prefs.getInt('firstCardIndex');
          if (firstCardIndex != null && firstCardIndex >= 0 && firstCardIndex < _cards.length) {
            _firstCard = _cards[firstCardIndex];
            print('Restored first card at index $firstCardIndex');
          }
          
          final int? secondCardIndex = prefs.getInt('secondCardIndex');
          if (secondCardIndex != null && secondCardIndex >= 0 && secondCardIndex < _cards.length) {
            _secondCard = _cards[secondCardIndex];
            print('Restored second card at index $secondCardIndex');
          }
        });
        
        // If we have both cards flipped, we need to process them
        if (_firstCard != null && _secondCard != null && !_isProcessing) {
          Future.delayed(Duration(milliseconds: 100), () {
            setState(() {
              _isProcessing = true;
            });
            _checkMatch();
          });
        }
        
        // Also save to GameStateManager for backup
        gameStateManager.saveGameState(
          cards: _cards,
          firstCard: _firstCard,
          secondCard: _secondCard,
          timeLeft: _timeLeft,
          isProcessing: _isProcessing,
          player1Score: _player1Score,
          player2Score: _player2Score,
          isPlayer1Turn: _isPlayer1Turn,
          isGamePaused: _isGamePaused,
          theme: widget.theme,
          isTwoPlayer: widget.isTwoPlayer,
        );
        
        print('Game state loaded successfully from SharedPreferences');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error loading game state: $e');
      return false;
    }
  }
  
  // Clear saved game state
  Future<void> _clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cards');
    await prefs.remove('cardStates');
    await prefs.remove('player1Score');
    await prefs.remove('player2Score');
    await prefs.remove('isPlayer1Turn');
    await prefs.remove('timeLeft');
    await prefs.remove('isTwoPlayer');
    await prefs.remove('theme');
    await prefs.remove('isGamePaused');
    await prefs.remove('isProcessing');
    await prefs.remove('firstCardIndex');
    await prefs.remove('secondCardIndex');
    await prefs.remove('lastSaveTime');
    await prefs.remove('isAddingTime');
    
    print('Game state cleared');
  }

  void _showGameOver() {
    _isGamePaused = true; // Mark game as paused but not reset
    _timer?.cancel(); // Pause the timer
    
    // Save game state to local storage
    _saveGameState();
    
    // Also save to GameStateManager
    gameStateManager.saveGameState(
      cards: _cards,
      firstCard: _firstCard,
      secondCard: _secondCard,
      timeLeft: _timeLeft,
      isProcessing: _isProcessing,
      player1Score: _player1Score,
      player2Score: _player2Score,
      isPlayer1Turn: _isPlayer1Turn,
      isGamePaused: _isGamePaused,
      theme: widget.theme,
      isTwoPlayer: widget.isTwoPlayer,
    );
    
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

    // Check if all cards are matched
    bool allCardsMatched = _cards.every((card) => card.isMatched);

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
                  allCardsMatched ? "Game Complete" : "Game Over",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: glowColor,
                    letterSpacing: 1.5,
                    shadows: [Shadow(blurRadius: 20, color: glowColor)],
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
                    // Clear any saved state in GameStateManager
                    gameStateManager.clearGameState();
                    
                    adHelper.showAd(
                      onAdClosed: () async {
                        Navigator.pop(context);
                        // Clear saved game state
                        await _clearGameState();
                        // Reset the game completely
                        setState(() {
                          _isGamePaused = false;
                        });
                        double screenWidth =
                            MediaQuery.of(context).size.width;
                        double screenHeight =
                            MediaQuery.of(context).size.height;
                        _initializeGame(screenWidth, screenHeight);
                      },
                    );
                  },
                  child: _buildButton(
                    Colors.blueAccent, // Always show button in active color
                    "Play Again",
                  ),
                ),
                
                // Only show +20 sec button if not all cards are matched and not in two-player mode
                if (!allCardsMatched && !widget.isTwoPlayer) ...[
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: () {
                      // Save game state in GameStateManager
                      gameStateManager.saveGameState(
                        cards: _cards,
                        firstCard: _firstCard,
                        secondCard: _secondCard,
                        timeLeft: _timeLeft,
                        isProcessing: _isProcessing,
                        player1Score: _player1Score,
                        player2Score: _player2Score,
                        isPlayer1Turn: _isPlayer1Turn,
                        isGamePaused: _isGamePaused,
                        theme: widget.theme,
                        isTwoPlayer: widget.isTwoPlayer,
                      );
                      
                      // Set adding time flag
                      gameStateManager.setAddingTime(true);
                      
                      // Also save to SharedPreferences for backup
                      _saveGameState();
                      
                      // Show the ad
                      adHelper.showAd(onAdClosed: () {
                        // Close the dialog first
                        Navigator.pop(context);
                        
                        // Restore game state and add time
                        _restoreGameStateFromManager();
                      });
                    },
                    child: _buildButton(
                      Colors.orangeAccent,
                      "+20 sec",
                      icon: Icons.access_time,
                    ),
                  ),
                ],
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

  Widget _buildScoreDisplay({
    required String imagePath,
    required int score,
    required Color glowColor,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glowColor, width: isActive ? 3 : 1.5),
        boxShadow:
            isActive
                ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
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

  // Restore card states after showing an ad
  Future<void> _restoreCardStatesAfterAd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear the adding time flag
      await prefs.remove('isAddingTime');
      
      // Get the saved card states
      final String? cardStatesJson = prefs.getString('cardStates');
      if (cardStatesJson == null) {
        print('No saved card states found');
        return;
      }
      
      final List<dynamic> cardStates = jsonDecode(cardStatesJson);
      
      // Only proceed if we have the same number of cards
      if (cardStates.length != _cards.length) {
        print('Card count mismatch: saved ${cardStates.length}, current ${_cards.length}');
        return;
      }
      
      // Update each card's state
      setState(() {
        for (int i = 0; i < cardStates.length; i++) {
          final Map<String, dynamic> state = cardStates[i];
          final int index = state['index'];
          
          if (index >= 0 && index < _cards.length) {
            _cards[index] = CardModel(
              imagePath: state['imagePath'],
              isFlipped: state['isFlipped'],
              isMatched: state['isMatched'],
            );
          }
        }
        
        // Reset first and second card references
        _firstCard = null;
        _secondCard = null;
        
        // Restore first and second card references if they exist
        final int? firstCardIndex = prefs.getInt('firstCardIndex');
        if (firstCardIndex != null && firstCardIndex >= 0 && firstCardIndex < _cards.length) {
          _firstCard = _cards[firstCardIndex];
          print('Restored first card at index $firstCardIndex');
        }
        
        final int? secondCardIndex = prefs.getInt('secondCardIndex');
        if (secondCardIndex != null && secondCardIndex >= 0 && secondCardIndex < _cards.length) {
          _secondCard = _cards[secondCardIndex];
          print('Restored second card at index $secondCardIndex');
        }
        
        // If we have both cards flipped, we need to process them
        if (_firstCard != null && _secondCard != null) {
          _isProcessing = true;
          Future.delayed(Duration(milliseconds: 100), () {
            _checkMatch();
          });
        }
      });
      
      print('Card states restored successfully');
    } catch (e) {
      print('Error restoring card states: $e');
    }
  }

  // Restore game state from AdHelper
  void _restoreGameStateFromAdHelper() {
    // Check if we have saved state in AdHelper
    if (AdHelper.savedCardStates == null || !AdHelper.isAddingTime) {
      print('No saved state in AdHelper');
      return;
    }
    
    try {
      // Create new cards with the saved state
      List<CardModel> newCards = List.generate(
        _cards.length,
        (index) => CardModel(imagePath: _cards[index].imagePath)
      );
      
      // Update each card's state
      for (var state in AdHelper.savedCardStates!) {
        final int index = state['index'];
        if (index >= 0 && index < newCards.length) {
          newCards[index] = CardModel(
            imagePath: state['imagePath'],
            isFlipped: state['isFlipped'],
            isMatched: state['isMatched'],
          );
        }
      }
      
      // Update the game state
      setState(() {
        // Update cards
        _cards = newCards;
        
        // Reset first and second card references
        _firstCard = null;
        _secondCard = null;
        
        // Restore first and second card references if they exist
        if (AdHelper.savedFirstCardIndex != null && 
            AdHelper.savedFirstCardIndex! >= 0 && 
            AdHelper.savedFirstCardIndex! < _cards.length) {
          _firstCard = _cards[AdHelper.savedFirstCardIndex!];
          print('Restored first card at index ${AdHelper.savedFirstCardIndex}');
        }
        
        if (AdHelper.savedSecondCardIndex != null && 
            AdHelper.savedSecondCardIndex! >= 0 && 
            AdHelper.savedSecondCardIndex! < _cards.length) {
          _secondCard = _cards[AdHelper.savedSecondCardIndex!];
          print('Restored second card at index ${AdHelper.savedSecondCardIndex}');
        }
        
        // Restore other game state
        _timeLeft = (AdHelper.savedTimeLeft ?? 60) + 20; // Add 20 seconds
        _isProcessing = AdHelper.savedIsProcessing ?? false;
        _player1Score = AdHelper.savedPlayer1Score ?? 0;
        _player2Score = AdHelper.savedPlayer2Score ?? 0;
        _isPlayer1Turn = AdHelper.savedIsPlayer1Turn ?? true;
        _isGamePaused = false;
        
        // If we have both cards flipped, we need to process them
        if (_firstCard != null && _secondCard != null && !_isProcessing) {
          _isProcessing = true;
          Future.delayed(Duration(milliseconds: 100), () {
            _checkMatch();
          });
        }
      });
      
      // Start the timer
      _startTimer();
      
      // Clear the saved state
      adHelper.clearGameState();
      
      print('Game state restored from AdHelper');
    } catch (e) {
      print('Error restoring game state from AdHelper: $e');
    }
  }

  // Restore game state from GameStateManager
  void _restoreGameStateFromManager() {
    // Check if we have saved state in GameStateManager
    if (!gameStateManager.hasSavedState()) {
      print('No saved state in GameStateManager');
      return;
    }
    
    try {
      // Make sure we have cards initialized
      if (_cards.isEmpty) {
        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;
        
        // Get the optimal grid size
        final gridSize = GameLogic().calculateOptimalGrid(screenWidth, screenHeight);
        final int rows = gridSize['rows']!;
        final int columns = gridSize['columns']!;
        
        // Check if the saved state has the same number of cards as our optimal grid
        final int optimalCardCount = rows * columns;
        final int? savedCardCount = gameStateManager.cardStates?.length;
        
        if (savedCardCount != null && savedCardCount != optimalCardCount) {
          print('Card count mismatch: saved $savedCardCount, optimal $optimalCardCount');
          // If the counts don't match, we need to initialize new cards
          _cards = GameLogic().getShuffledCards(widget.theme, screenWidth, screenHeight);
          print('Cards initialized in _restoreGameStateFromManager with new dimensions');
        } else {
          _cards = GameLogic().getShuffledCards(widget.theme, screenWidth, screenHeight);
          print('Cards initialized in _restoreGameStateFromManager');
        }
      }
      
      // Create new cards with the saved state
      List<CardModel> newCards = List.generate(
        _cards.length,
        (index) => CardModel(imagePath: _cards[index].imagePath)
      );
      
      // Update each card's state
      if (gameStateManager.cardStates != null) {
        // Only update cards that exist in both the saved state and our current grid
        for (var state in gameStateManager.cardStates!) {
          final int index = state['index'];
          if (index >= 0 && index < newCards.length) {
            newCards[index] = CardModel(
              imagePath: state['imagePath'],
              isFlipped: state['isFlipped'],
              isMatched: state['isMatched'],
            );
          }
        }
      }
      
      // Update the game state
      setState(() {
        // Update cards
        _cards = newCards;
        
        // Reset first and second card references
        _firstCard = null;
        _secondCard = null;
        
        // Restore first and second card references if they exist
        if (gameStateManager.firstCardIndex != null && 
            gameStateManager.firstCardIndex! >= 0 && 
            gameStateManager.firstCardIndex! < _cards.length) {
          _firstCard = _cards[gameStateManager.firstCardIndex!];
          print('Restored first card at index ${gameStateManager.firstCardIndex}');
        }
        
        if (gameStateManager.secondCardIndex != null && 
            gameStateManager.secondCardIndex! >= 0 && 
            gameStateManager.secondCardIndex! < _cards.length) {
          _secondCard = _cards[gameStateManager.secondCardIndex!];
          print('Restored second card at index ${gameStateManager.secondCardIndex}');
        }
        
        // Restore other game state
        _timeLeft = (gameStateManager.timeLeft ?? 60) + 20; // Add 20 seconds
        _isProcessing = gameStateManager.isProcessing ?? false;
        _player1Score = gameStateManager.player1Score ?? 0;
        _player2Score = gameStateManager.player2Score ?? 0;
        _isPlayer1Turn = gameStateManager.isPlayer1Turn ?? true;
        _isGamePaused = false;
      });
      
      // If we have both cards flipped, we need to process them
      if (_firstCard != null && _secondCard != null && !_isProcessing) {
        Future.delayed(Duration(milliseconds: 100), () {
          setState(() {
            _isProcessing = true;
          });
          _checkMatch();
        });
      }
      
      // Start the timer
      _startTimer();
      
      // Clear the adding time flag
      gameStateManager.setAddingTime(false);
      
      // Save the state to SharedPreferences as well for backup
      _saveGameState();
      
      print('Game state restored from GameStateManager');
    } catch (e) {
      print('Error restoring game state from GameStateManager: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate grid dimensions
    final gridSize = _cards.isNotEmpty 
        ? GameLogic().calculateOptimalGrid(screenWidth, screenHeight)
        : {'rows': 4, 'columns': 4};
    
    final int columns = gridSize['columns']!;
    final int rows = gridSize['rows']!;
    
    // Calculate total grid capacity
    final int gridCapacity = rows * columns;
    
    // Determine if scrolling should be enabled
    // Enable scrolling only if we have more cards than the grid can display
    final bool enableScrolling = _cards.length > gridCapacity;
    
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
              padding: const EdgeInsets.only(
                top: 40,
                left: 12,
                right: 12,
                bottom: 8,
              ), // Smaller padding
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Timer with animated glow effect
                      if (!widget.isTwoPlayer)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ), // Smaller padding
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Smaller border radius
                            border: Border.all(
                              color:
                                  _timeLeft > 60
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
                              Icon(
                                Icons.timer,
                                color: Colors.white,
                                size: 22,
                              ), // Smaller icon
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: Align(
                  alignment: Alignment.centerLeft, // Align it to the left
                  child: FractionallySizedBox(
                    alignment:
                        Alignment.centerLeft, // Keep the start fixed at left
                    widthFactor: _timeLeft / 60, // Shrinks from right to left
                    child: NeonSeekBar(
                      progress: 1, // Always full internally
                      glowColor:
                          _timeLeft > 30
                              ? Colors.greenAccent
                              : _timeLeft > 20
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
                physics: enableScrolling 
                    ? AlwaysScrollableScrollPhysics() // Allow scrolling if needed
                    : NeverScrollableScrollPhysics(), // Disable scrolling if all cards fit
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder:
                    (_, index) => MemoryCard(
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
