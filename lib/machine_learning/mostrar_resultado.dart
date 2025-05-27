import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> mostrarResultadoML(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final datos = doc.data();
    if (datos != null && datos.containsKey('resultado_ml')) {
      final resultado = datos['resultado_ml'];
      final double score = (resultado['anomaly_score'] as num).toDouble();
      final bool esAnomalo = resultado['es_anomalo'] == true;

      if (esAnomalo) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('⚠️ Posible patrón anómalo'),
            content: Text(
              'Se ha detectado un comportamiento fuera del patrón normal.\n\n'
              'Puntaje de anomalía: ${score.toStringAsFixed(3)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('✅ Evaluación normal'),
            content: Text(
              'No se ha detectado ningún patrón anómalo en tu rendimiento.\n\n'
              'Puntaje: ${score.toStringAsFixed(3)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sin datos'),
          content: const Text(
              'Aún no se ha generado un análisis para tu cuenta. Juega primero para obtener un resultado.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }
}