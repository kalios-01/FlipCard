class CardModel {
  final String imagePath;
  bool isFlipped;
  bool isMatched;

  CardModel({required this.imagePath, this.isFlipped = false, this.isMatched = false});
}
