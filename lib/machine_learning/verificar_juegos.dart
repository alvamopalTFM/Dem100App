import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mostrar_resultado.dart';

Future<void> verificarYMostrarResultado(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  final List<String> minijuegos = [
    'stroop_tests',
    'nback_tests',
    'laberinto_tests',
    'secuencia_acciones_tests',
    'memoria_secuencial_tests',
    'categorizacion_rapida_tests',
  ];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool tieneMinimoDeTodo = true;

  for (String juego in minijuegos) {
    final querySnapshot = await firestore
        .collection(juego)
        .where('uid', isEqualTo: uid)
        .get();

    if (querySnapshot.size < 1) {
      tieneMinimoDeTodo = false;
      break;
    }
  }

  if (tieneMinimoDeTodo) {
    // ignore: use_build_context_synchronously
    await mostrarResultadoML(context);
  } else {
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Datos insuficientes'),
        content: const Text(
          'Para mostrar un resultado de análisis cognitivo, debes jugar al menos 1 partida en cada minijuego.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}