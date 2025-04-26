import 'package:flutter/material.dart';

class TestNBackPage extends StatefulWidget {
  const TestNBackPage({Key? key}) : super(key: key);

  @override
  State<TestNBackPage> createState() => _TestNBackPageState();
}

class _TestNBackPageState extends State<TestNBackPage> {
  int highlightedIndex = -1; // Para saber qué casilla está iluminada (-1 = ninguna)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de N-Back'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildGrid(), // 👈 Aquí dibujamos la cuadrícula 3x3
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // De momento, ilumina una casilla al azar al pulsar
                setState(() {
                  highlightedIndex = (highlightedIndex + 1) % 9; // Modo prueba
                });
              },
              child: const Text('Siguiente estímulo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildGrid() {
    return SizedBox(
      width: 300,
      height: 300,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(), // No scroll
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 columnas
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9, // 9 celdas
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: index == highlightedIndex ? Colors.blue : Colors.grey[300],
              border: Border.all(color: Colors.black),
            ),
          );
        },
      ),
    );
  }
}