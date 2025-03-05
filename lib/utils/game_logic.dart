import '../models/card_model.dart';
import '../models/themes.dart';

class GameLogic {
  List<CardModel> getShuffledCards(String theme, double screenWidth) {
    final List<String> allImages = themes[theme] ?? [];
    allImages.shuffle();
    // 🟢 Choose 8 images (16 cards) for large screens, 12 images (24 cards) for smaller screens
    final int imageCount = screenWidth > 600 ? 8 : 12;
    final List<String> selectedImages = allImages.take(imageCount).toList();

    List<CardModel> cards = [];
    for (String image in selectedImages) {
      cards.add(CardModel(imagePath: image));
      cards.add(CardModel(imagePath: image)); // Duplicate for matching
    }

    cards.shuffle();
    return cards;
  }
}