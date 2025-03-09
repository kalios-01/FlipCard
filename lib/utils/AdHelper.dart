import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/card_model.dart';

class AdHelper {
  static final AdHelper _instance = AdHelper._internal();

  // Static variables to store game state during ad display
  static List<Map<String, dynamic>>? savedCardStates;
  static int? savedFirstCardIndex;
  static int? savedSecondCardIndex;
  static int? savedTimeLeft;
  static bool? savedIsProcessing;
  static int? savedPlayer1Score;
  static int? savedPlayer2Score;
  static bool? savedIsPlayer1Turn;
  static bool isAddingTime = false;

  factory AdHelper() {
    return _instance;
  }

  AdHelper._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  /// TODO: Replace with your actual AdMob Ad Unit IDs
  final String interstitialAdUnitId = "ca-app-pub-7322204604787687/8928795926";
  final String rewardedAdUnitId = "ca-app-pub-7322204604787687/4765295416";

  // Save game state before showing ad
  void saveGameState({
    required List<CardModel> cards,
    required CardModel? firstCard,
    required CardModel? secondCard,
    required int timeLeft,
    required bool isProcessing,
    required int player1Score,
    required int player2Score,
    required bool isPlayer1Turn,
  }) {
    // Save card states
    savedCardStates =
        cards.asMap().entries.map((entry) {
          return {
            'index': entry.key,
            'imagePath': entry.value.imagePath,
            'isFlipped': entry.value.isFlipped,
            'isMatched': entry.value.isMatched,
          };
        }).toList();

    // Save first and second card indices
    savedFirstCardIndex = firstCard != null ? cards.indexOf(firstCard) : null;
    savedSecondCardIndex =
        secondCard != null ? cards.indexOf(secondCard) : null;

    // Save other game state
    savedTimeLeft = timeLeft;
    savedIsProcessing = isProcessing;
    savedPlayer1Score = player1Score;
    savedPlayer2Score = player2Score;
    savedIsPlayer1Turn = isPlayer1Turn;

    // Set flag for adding time
    isAddingTime = true;

    print(
      'Game state saved in AdHelper: ${savedCardStates?.length} cards, timeLeft: $savedTimeLeft',
    );
  }

  // Clear saved game state
  void clearGameState() {
    savedCardStates = null;
    savedFirstCardIndex = null;
    savedSecondCardIndex = null;
    savedTimeLeft = null;
    savedIsProcessing = null;
    savedPlayer1Score = null;
    savedPlayer2Score = null;
    savedIsPlayer1Turn = null;
    isAddingTime = false;

    print('Game state cleared in AdHelper');
  }

  /// Load Interstitial Ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialAd = null;
          print("Interstitial Ad failed to load: $error");
        },
      ),
    );
  }

  /// Load Rewarded Ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          print("Rewarded Ad failed to load: $error");
        },
      ),
    );
  }

  /// Show Interstitial Ad (Fallback to Rewarded Ad if Interstitial is unavailable)
  void showAd({Function? onAdClosed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd(); // Reload ad after showing
          if (onAdClosed != null) onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _interstitialAd = null;
          print("Interstitial Ad failed to show: $error");
          _showRewardedAd(onAdClosed: onAdClosed); // Fallback to Rewarded Ad
        },
      );
      _interstitialAd!.show();
    } else {
      print("Interstitial Ad not available, trying Rewarded Ad...");
      _showRewardedAd(onAdClosed: onAdClosed);
    }
  }

  /// Show Rewarded Ad
  void _showRewardedAd({Function? onAdClosed}) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd(); // Reload ad after showing
          if (onAdClosed != null) onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          ad.dispose();
          _rewardedAd = null;
          print("Rewarded Ad failed to show: $error");
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print("User earned reward: ${reward.amount} ${reward.type}");
        },
      );
    } else {
      print("No Rewarded Ad available.");
    }
  }

  /// Preload Ads on App Start
  void preloadAds() {
    loadInterstitialAd();
    loadRewardedAd();
  }
}
