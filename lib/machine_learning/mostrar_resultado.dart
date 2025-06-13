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
      final int etiqueta = resultado['etiqueta'] ?? -1;

      String titulo;
      String mensaje;
      Icon icono;

      switch (etiqueta) {
        case 0:
          titulo = 'Todo va bien';
          mensaje = 'Tu rendimiento es adecuado y no presenta problemas.';
          icono = const Icon(Icons.check_circle, color: Colors.green, size: 48);
          break;
        case 1:
          titulo = 'Aviso';
          mensaje = 'Tu rendimiento presenta algunas irregularidades. Intenta mejorar en algunos minijuegos.';
          icono = const Icon(Icons.warning, color: Colors.orange, size: 48);
          break;
        case 2:
          titulo = 'Posible dificultad';
          mensaje = 'Se ha detectado un rendimiento preocupante. Consulta con un profesional si lo ves necesario.';
          icono = const Icon(Icons.error, color: Colors.red, size: 48);
          break;
        default:
          titulo = 'Sin datos válidos';
          mensaje = 'No se pudo obtener una evaluación válida.';
          icono = const Icon(Icons.info, size: 48);
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              icono,
              const SizedBox(width: 12),
              Expanded(child: Text(titulo)),
            ],
          ),
          content: Text(mensaje),
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
          title: const Text('Sin análisis disponible'),
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
