import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlipCard());
}

class FlipCard extends StatelessWidget {
  const FlipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flip Card',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StartScreen(),
    );
  }
}
