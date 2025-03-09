import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';

// A singleton class to manage game state globally
class GameStateManager {
  static final GameStateManager _instance = GameStateManager._internal();

  factory GameStateManager() {
    return _instance;
  }

  GameStateManager._internal();

  // Game state variables
  List<Map<String, dynamic>>? _cardStates;
  int? _firstCardIndex;
  int? _secondCardIndex;
  int? _timeLeft;
  bool? _isProcessing;
  int? _player1Score;
  int? _player2Score;
  bool? _isPlayer1Turn;
  bool _isAddingTime = false;
  bool _isGamePaused = false;
  String? _theme;
  bool? _isTwoPlayer;

  // Getters
  List<Map<String, dynamic>>? get cardStates => _cardStates;
  int? get firstCardIndex => _firstCardIndex;
  int? get secondCardIndex => _secondCardIndex;
  int? get timeLeft => _timeLeft;
  bool? get isProcessing => _isProcessing;
  int? get player1Score => _player1Score;
  int? get player2Score => _player2Score;
  bool? get isPlayer1Turn => _isPlayer1Turn;
  bool get isAddingTime => _isAddingTime;
  bool get isGamePaused => _isGamePaused;
  String? get theme => _theme;
  bool? get isTwoPlayer => _isTwoPlayer;

  // Save game state
  void saveGameState({
    required List<CardModel> cards,
    required CardModel? firstCard,
    required CardModel? secondCard,
    required int timeLeft,
    required bool isProcessing,
    required int player1Score,
    required int player2Score,
    required bool isPlayer1Turn,
    required bool isGamePaused,
    required String theme,
    required bool isTwoPlayer,
  }) {
    // Save card states
    _cardStates = cards.asMap().entries.map((entry) {
      return {
        'index': entry.key,
        'imagePath': entry.value.imagePath,
        'isFlipped': entry.value.isFlipped,
        'isMatched': entry.value.isMatched,
      };
    }).toList();
    
    // Save first and second card indices
    _firstCardIndex = firstCard != null ? cards.indexOf(firstCard) : null;
    _secondCardIndex = secondCard != null ? cards.indexOf(secondCard) : null;
    
    // Save other game state
    _timeLeft = timeLeft;
    _isProcessing = isProcessing;
    _player1Score = player1Score;
    _player2Score = player2Score;
    _isPlayer1Turn = isPlayer1Turn;
    _isGamePaused = isGamePaused;
    _theme = theme;
    _isTwoPlayer = isTwoPlayer;
    
    print('Game state saved in GameStateManager: ${_cardStates?.length} cards, timeLeft: $_timeLeft');
  }

  // Set adding time flag
  void setAddingTime(bool value) {
    _isAddingTime = value;
    print('Setting isAddingTime to $value');
  }

  // Clear saved game state
  void clearGameState() {
    _cardStates = null;
    _firstCardIndex = null;
    _secondCardIndex = null;
    _timeLeft = null;
    _isProcessing = null;
    _player1Score = null;
    _player2Score = null;
    _isPlayer1Turn = null;
    _isAddingTime = false;
    _isGamePaused = false;
    _theme = null;
    _isTwoPlayer = null;
    
    print('Game state cleared in GameStateManager');
  }

  // Check if we have saved state
  bool hasSavedState() {
    return _cardStates != null;
  }

  // Check if theme and game mode match
  bool isStateCompatible(String theme, bool isTwoPlayer) {
    return _theme == theme && _isTwoPlayer == isTwoPlayer;
  }
} 