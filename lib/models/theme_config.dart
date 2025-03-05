class ThemeConfig {
  static Map<String, String> themescardcover = {
    'SquidGame': 'assets/squidgame/cardcover.png',
    'Alice In Borderland': 'assets/aliceinborderland/cardcover.png',
    'Stranger Things': 'assets/strangerthings/cardcover.png',
    'Billy and Mandy': 'assets/billyandmandy/cardcover.png',
    'Minecraft': 'assets/minecraft/cardcover.png',
    'Oggy And The Cockroaches': 'assets/oggyandthecockroaches/cardcover.png',
    'From': 'assets/from/cardcover.png',
    // You can add more themes here dynamically in the future.
  };

  // Get the card front image path dynamically for the selected theme
  static String getCardFront(String theme) {
    return themescardcover[theme] ?? 'assets/squidgame/cardcover.png'; // default fallback
  }
}
