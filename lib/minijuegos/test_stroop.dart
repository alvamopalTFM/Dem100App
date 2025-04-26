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
    'Azul', 'Amarillo', 'Rojo', 'Rosa', 'Naranja', 'Verde',
    'Morado', 'Marrón', 'Negro', 'Blanco', 'Gris',
  ];

  final Map<String, Color> colorMap = {
    'Azul': Colors.blue,
    'Amarillo': Colors.yellow,
    'Rojo': Colors.red,
    'Rosa': Colors.pink,
    'Naranja': Colors.orange,
    'Verde': Colors.green,
    'Morado': Colors.purple,
    'Marrón': Colors.brown,
    'Negro': Colors.black,
    'Blanco': Colors.white,
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
    currentWord = 'Azul'; // Valor inicial seguro para evitar errores
    currentColor = Colors.blue; // Valor inicial seguro para evitar errores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showInstructions();
      generateNewChallenge(); // Generamos ya la primera palabra
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
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
            },
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
      setState(() {
        score++;
      });
    } else {
      setState(() {
        mistakes++;
      });
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
    List<Widget> rows = [];

    rows.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.sublist(0, 3).map((colorName) => buildColorButton(colorName)).toList(),
      ),
    );

    rows.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.sublist(3, 6).map((colorName) => buildColorButton(colorName)).toList(),
      ),
    );

    rows.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: colors.sublist(6, 9).map((colorName) => buildColorButton(colorName)).toList(),
      ),
    );

    rows.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: colors.sublist(9, 11).map((colorName) => buildColorButton(colorName)).toList(),
      ),
    );

    return rows;
  }

  Widget buildColorButton(String colorName) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: 100,
        height: 50,
        child: ElevatedButton(
          onPressed: () => handleAnswer(colorName),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorMap[colorName],
          ),
          child: Text(
            colorName,
            style: TextStyle(
              color: (colorName == 'Blanco' || colorName == 'Amarillo') ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
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



