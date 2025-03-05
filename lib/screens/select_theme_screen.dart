import 'package:flutter/material.dart';
import 'game_screen.dart';
import '../models/themes.dart';

class SelectThemeScreen extends StatefulWidget {
  final bool isTwoPlayer;

  const SelectThemeScreen({super.key, required this.isTwoPlayer});

  @override
  _SelectThemeScreenState createState() => _SelectThemeScreenState();
}

class _SelectThemeScreenState extends State<SelectThemeScreen> {
  String _searchText = '';

  void _startGame(BuildContext context, String theme) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(theme: theme, isTwoPlayer: widget.isTwoPlayer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtering themes based on search text
    List<String> filteredThemes = themes.keys
        .where((theme) => theme.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();

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
            // AppBar with Centered Title
            AppBar(
              backgroundColor: Colors.transparent, // ✅ Blends with background
              elevation: 0,
              automaticallyImplyLeading: false, // ✅ Removes back button
              title: const Text(
                "Select Card Theme",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28, // ✅ Larger title
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              centerTitle: true,
            ),

            // Wrapped Search Bar with Shadow Effect
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => setState(() => _searchText = value),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Search Theme",
                    hintStyle: const TextStyle(color: Colors.black54),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Theme Grid with Modern Styling
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two columns
                  childAspectRatio: 2 / 3, // ✅ Vertical rectangular cards
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredThemes.length,
                itemBuilder: (context, index) {
                  String theme = filteredThemes[index];
                  return GestureDetector(
                    onTap: () => _startGame(context, theme),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250), // ✅ Smooth tap effect
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2), // ✅ White thin border
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                                themes[theme]!.first,
                                fit: BoxFit.cover
                            ),
                            // Optional: Add overlay or text to theme card
                            Container(
                              alignment: Alignment.center,
                              color: Colors.black.withOpacity(0.5),
                              child: Text(
                                theme, // Show theme name as overlay
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
