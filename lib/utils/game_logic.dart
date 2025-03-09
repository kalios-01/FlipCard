import '../models/card_model.dart';
import '../models/themes.dart';

class GameLogic {
  // Calculate the grid size based on screen dimensions
  Map<String, int> calculateOptimalGrid(double screenWidth, double screenHeight) {
    int columns;
    int rows;
    
    // Categorize screen sizes
    if (screenWidth < 360 || screenHeight < 640) {
      // Small screen (e.g., older phones)
      columns = 4;
      rows = 5;
      print('Using small screen layout: 4x5 grid (20 cards)');
    } else if (screenWidth < 600 || screenHeight < 800) {
      // Medium screen (e.g., most phones)
      columns = 4;
      rows = 6;
      print('Using medium screen layout: 4x6 grid (24 cards)');
    } else {
      // Large screen (e.g., tablets, large phones)
      columns = 6;
      rows = 8;
      print('Using large screen layout: 6x8 grid (48 cards)');
    }
    
    // Calculate available space for cards (for debugging purposes)
    double availableHeight = screenHeight - 180; // Subtract space for header, timer, etc.
    double availableWidth = screenWidth - 32; // Subtract horizontal padding
    
    // Calculate card dimensions based on a 3:4 aspect ratio
    double cardWidth = (availableWidth / columns) - 8; // Subtract spacing
    double cardHeight = cardWidth * (4/3); // 3:4 aspect ratio
    
    // Calculate how many rows would theoretically fit (for debugging)
    int theoreticalRows = (availableHeight / (cardHeight + 8)).floor();
    
    print('Screen dimensions: ${screenWidth.toInt()}x${screenHeight.toInt()}');
    print('Card dimensions: ${cardWidth.toInt()}x${cardHeight.toInt()}');
    print('Theoretical max rows: $theoreticalRows, Using: $rows rows');
    
    return {
      'rows': rows,
      'columns': columns
    };
  }

  List<CardModel> getShuffledCards(String theme, double screenWidth, double screenHeight) {
    final List<String> allImages = themes[theme] ?? [];
    allImages.shuffle();
    
    // Calculate grid size based on screen dimensions
    final gridSize = calculateOptimalGrid(screenWidth, screenHeight);
    final int rows = gridSize['rows']!;
    final int columns = gridSize['columns']!;
    
    // Calculate total number of pairs needed for this grid
    final int totalPairs = (rows * columns) ~/ 2;
    
    print('Creating memory game with $totalPairs pairs (${totalPairs * 2} cards)');
    
    // Make sure we have enough images for the pairs
    if (totalPairs > allImages.length) {
      print('Warning: Not enough images in theme. Need $totalPairs, have ${allImages.length}');
      // If we don't have enough images, we'll duplicate some
      while (allImages.length < totalPairs) {
        allImages.addAll(allImages.take(totalPairs - allImages.length));
      }
    }
    
    // Select images for the pairs
    final List<String> selectedImages = allImages.take(totalPairs).toList();

    List<CardModel> cards = [];
    for (String image in selectedImages) {
      cards.add(CardModel(imagePath: image));
      cards.add(CardModel(imagePath: image)); // Duplicate for matching
    }

    cards.shuffle();
    return cards;
  }
}