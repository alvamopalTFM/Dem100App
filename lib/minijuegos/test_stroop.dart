import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestStroopPage extends StatefulWidget {
  const TestStroopPage({Key? key}) : super(key: key);

  @override
  State<TestStroopPage> createState() => _TestStroopPageState();
}

class _TestStroopPageState extends State<TestStroopPage> {
  final List<String> colors = [
    'Azul', 'Amarillo', 'Rojo', 'Naranja', 'Verde',
    'Morado', 'Marrón', 'Negro', 'Gris',
  ];

  final Map<String, Color> colorMap = {
    'Azul': Colors.blue,
    'Amarillo': Colors.yellow,
    'Rojo': Colors.red,
    'Naranja': Colors.orange,
    'Verde': Colors.green,
    'Morado': Colors.purple,
    'Marrón': Colors.brown,
    'Negro': Colors.black,
    'Gris': Colors.grey,
  };

  late String currentWord;
  late Color currentColor;
  int score = 0;
  int mistakes = 0;
  int totalAttempts = 0;
  final int maxAttempts = 20;

  final Random random = Random();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    currentWord = 'Azul';
    currentColor = Colors.blue;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showInstructions();
      generateNewChallenge();
    });
  }

  void showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Instrucciones'),
        content: const Text(
          'En este test, debes pulsar el botón del color en que está escrita la palabra, '
          'no el significado de la palabra.\n\n'
          'Ejemplo: si ves la palabra "Rojo" escrita en color azul, debes pulsar "Azul".',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void generateNewChallenge() {
    final randomWord = colors[random.nextInt(colors.length)];
    final randomColor = colorMap[colors[random.nextInt(colors.length)]]!;

    setState(() {
      currentWord = randomWord;
      currentColor = randomColor;
    });
  }

  void handleAnswer(String selectedColor) {
    if (colorMap[selectedColor] == currentColor) {
      score++;
    } else {
      mistakes++;
    }

    totalAttempts++;

    if (totalAttempts >= maxAttempts) {
      endGame();
    } else {
      generateNewChallenge();
    }
  }

  Future<void> endGame() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('stroop_tests').add({
        'uid': user.uid,
        'email': user.email,
        'score': score,
        'mistakes': mistakes,
        'timestamp': Timestamp.now(),
      });
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Test Finalizado!'),
        content: Text('Aciertos: $score\nFallos: $mistakes'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<Widget> buildButtons() {
    return [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: colors.map((colorName) => buildColorButton(colorName)).toList(),
      ),
    ];
  }

  Widget buildColorButton(String colorName) {
    return SizedBox(
      width: 110,
      height: 55,
      child: ElevatedButton(
        onPressed: () => handleAnswer(colorName),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorMap[colorName],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            colorName,
            style: TextStyle(
              color: (colorName == 'Amarillo') ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Stroop'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aciertos: $score    Fallos: $mistakes',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            Text(
              currentWord,
              style: TextStyle(
                fontSize: 40,
                color: currentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ...buildButtons(),
          ],
        ),
      ),
    );
  }
}





