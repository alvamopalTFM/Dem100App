import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategorizacionRapidaPage extends StatefulWidget {
  const CategorizacionRapidaPage({Key? key}) : super(key: key);

  @override
  State<CategorizacionRapidaPage> createState() => _CategorizacionRapidaPageState();
}

class _CategorizacionRapidaPageState extends State<CategorizacionRapidaPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int tiempoLimite = 60;
  late Timer timer;
  int tiempoRestante = 60;

  int aciertos = 0;
  int errores = 0;

  String palabraActual = '';
  String categoriaCorrecta = '';
  String? ultimaPalabraMostrada;

  final List<String> categorias = ['Animales', 'Frutas', 'Vehículos'];

  final Map<String, String> palabras = {
    'Perro': 'Animales',
    'Gato': 'Animales',
    'León': 'Animales',
    'Manzana': 'Frutas',
    'Banana': 'Frutas',
    'Uva': 'Frutas',
    'Coche': 'Vehículos',
    'Camión': 'Vehículos',
    'Moto': 'Vehículos',
  };

  final Random random = Random();

  bool juegoIniciado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarInstrucciones();
    });
  }

  void _mostrarInstrucciones() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Instrucciones'),
        content: const Text(
          'Clasifica la palabra que aparece tocando la categoría correcta.\n\n'
          'Tienes 60 segundos para clasificar el mayor número posible.\n\n'
          '¡Empieza cuando pulses OK!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _empezarJuego();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _empezarJuego() {
    _siguientePalabra();
    juegoIniciado = true;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        tiempoRestante--;
        if (tiempoRestante <= 0) {
          timer.cancel();
          _finalizarJuego();
        }
      });
    });
  }

  void _siguientePalabra() {
    final palabrasKeys = palabras.keys.toList();
    String nuevaPalabra;

    do {
      nuevaPalabra = palabrasKeys[random.nextInt(palabrasKeys.length)];
    } while (nuevaPalabra == ultimaPalabraMostrada);

    setState(() {
      palabraActual = nuevaPalabra;
      categoriaCorrecta = palabras[nuevaPalabra]!;
      ultimaPalabraMostrada = nuevaPalabra;
    });
  }

  void _seleccionarCategoria(String categoria) {
    if (!juegoIniciado) return;

    if (categoria == categoriaCorrecta) {
      aciertos++;
    } else {
      errores++;
    }
    _siguientePalabra();
  }

  void _finalizarJuego() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('categorizacion_rapida_tests').add({
        'uid': user.uid,
        'email': user.email,
        'aciertos': aciertos,
        'errores': errores,
        'timestamp': Timestamp.now(),
      });
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Fin del juego'),
        content: Text('Aciertos: $aciertos\nErrores: $errores'),
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

  @override
  void dispose() {
    if (juegoIniciado && timer.isActive) timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorización Rápida'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tiempo restante: $tiempoRestante s',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              Text(
                palabraActual,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: categorias.map((categoria) {
                  return ElevatedButton(
                    onPressed: () => _seleccionarCategoria(categoria),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text(categoria, style: const TextStyle(fontSize: 18)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              Text(
                'Aciertos: $aciertos    Errores: $errores',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}