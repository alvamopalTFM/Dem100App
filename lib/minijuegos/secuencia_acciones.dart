import 'dart:async' as async;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:dem100app/machine_learning/api_ml.dart';


class SecuenciaAccionesPage extends StatefulWidget {
  const SecuenciaAccionesPage({Key? key}) : super(key: key);

  @override
  State<SecuenciaAccionesPage> createState() => _SecuenciaAccionesPageState();
}

class _SecuenciaAccionesPageState extends State<SecuenciaAccionesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String objetivo;
  late List<String> accionesCorrectas;
  late List<String> accionesDistractoras;
  late List<String> accionesDisponibles;

  List<String> accionesSeleccionadas = [];
  int intentos = 0;
  bool instruccionesMostradas = false;
  late Stopwatch stopwatch;

  final Random random = Random();

  final List<Map<String, dynamic>> objetivos = [
    {
      'objetivo': 'Entra en casa y enciende la luz',
      'correctas': ['Encontrar la llave', 'Abrir la puerta', 'Encender el interruptor'],
      'distractoras': ['Cerrar ventana', 'Beber agua', 'Sentarse en el sofá'],
    },
    {
      'objetivo': 'Prepara una comida',
      'correctas': ['Ir a la cocina', 'Encender la cocina', 'Cocinar los alimentos'],
      'distractoras': ['Encender la tele', 'Leer un libro', 'Tocar la guitarra'],
    },
    {
      'objetivo': 'Arranca el coche',
      'correctas': ['Coger las llaves', 'Entrar en el coche', 'Girar la llave en el contacto'],
      'distractoras': ['Cambiar una rueda', 'Abrir el maletero', 'Tocar el claxon'],
    },
    {
      'objetivo': 'Hacer un cafe',
      'correctas': ['Poner agua en la cafetera', 'Añadir cafe', 'Encender la cafetera'],
      'distractoras': ['Cortar pan', 'Poner la mesa', 'Pelar una naranja'],
    },
    {
      'objetivo': 'Colgar un cuadro',
      'correctas': ['Marcar la pared', 'Clavar el clavo', 'Colgar el cuadro'],
      'distractoras': ['Barrer el suelo', 'Regar las plantas', 'Coger una sierra'],
    },
    {
      'objetivo': 'Cambiar una bombilla',
      'correctas': ['Quitar la bombilla vieja', 'Poner la bombilla nueva', 'Encender la luz'],
      'distractoras': ['Salir de casa', 'Ir al baño', 'Buscar un martillo'],
    },
    {
      'objetivo': 'Leer un libro en la cama',
      'correctas': ['Encender la luz', 'Buscar el libro', 'Acostarse'],
      'distractoras': ['Abrir la ventana', 'Coger el telefono', 'Coger comida'],
    },
    {
      'objetivo': 'Lavarse los dientes',
      'correctas': ['Poner pasta en el cepillo', 'Cepillarse los dientes', 'Enjuagarse la boca'],
      'distractoras': ['Ir a la cocina', 'Darse una ducha', 'Aplicar crema facial'],
    },
    {
      'objetivo': 'Lavar la ropa',
      'correctas': ['Meter la ropa en la lavadora', 'Poner detergente', 'Encender la lavadora'],
      'distractoras': ['Pasar el aspirador', 'Encender la secadora', 'Lavarse las manos'],
    },
  ];

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    _seleccionarObjetivo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarInstrucciones();
    });
  }

  void _seleccionarObjetivo() {
    final elegido = objetivos[random.nextInt(objetivos.length)];
    objetivo = elegido['objetivo'];
    accionesCorrectas = List<String>.from(elegido['correctas']);
    accionesDistractoras = List<String>.from(elegido['distractoras']);
    accionesDisponibles = [...accionesCorrectas, ...accionesDistractoras];
    accionesDisponibles.shuffle();
  }

  void _mostrarInstrucciones() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Instrucciones'),
        content: Text(
          'Tu objetivo es:\n\n'
          '$objetivo\n\n'
          'Toca las acciones en el orden correcto para lograrlo.\n'
          '¡Cuidado! Hay acciones trampa.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              stopwatch.start();
              setState(() {
                instruccionesMostradas = true;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

void seleccionarAccion(String accion) {
  if (accionesSeleccionadas.length < 3) {
    setState(() {
      accionesDisponibles.remove(accion);
      accionesSeleccionadas.add(accion);
    });
  }
}


  void deseleccionarAccion(String accion) {
    setState(() {
      accionesSeleccionadas.remove(accion);
      accionesDisponibles.add(accion);
      accionesDisponibles.shuffle();
    });
  }

  void comprobarSecuencia() async {
    intentos++;

    bool correcto = true;
    if (accionesSeleccionadas.length != accionesCorrectas.length) {
      correcto = false;
    } else {
      for (int i = 0; i < accionesCorrectas.length; i++) {
        if (accionesSeleccionadas[i] != accionesCorrectas[i]) {
          correcto = false;
          break;
        }
      }
    }

    if (correcto) {
      stopwatch.stop();
      final User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('secuencia_acciones_tests').add({
          'uid': user.uid,
          'email': user.email,
          'objetivo': objetivo,
          'acciones_correctas': accionesCorrectas,
          'acciones_finales': accionesSeleccionadas,
          'intentos': intentos - 1, // porque primer intento correcto cuenta como 0 fallos
          'tiempo_segundos': stopwatch.elapsed.inSeconds,
          'timestamp': Timestamp.now(),
        });
        await lanzarEvaluacionML();
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Correcto!'),
          content: Text(
            'Has completado la secuencia correctamente.\n'
            'Intentos: ${intentos - 1}\n'
            'Tiempo: ${stopwatch.elapsed.inSeconds} segundos',
          ),
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
    } else {
      if (!mounted) return;
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    title: const Text('¡Secuencia incorrecta!'),
    content: const Text('Inténtalo de nuevo.'),
    actions: [
      TextButton(
        onPressed: () {
          setState(() {
            // Mover las seleccionadas de nuevo a disponibles
            accionesDisponibles.addAll(accionesSeleccionadas);
            accionesSeleccionadas.clear();
          });
          Navigator.of(context).pop();
        },
        child: const Text('Intentarlo de nuevo'),
      ),
    ],
  ),
);

    }
  }

  Widget buildAccionDisponible(String accion) {
    return GestureDetector(
      onTap: () => seleccionarAccion(accion),
      child: Card(
        elevation: 3,
        color: Colors.lightBlueAccent.shade100,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              accion,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

Widget buildAccionSeleccionada(int index) {
  String? accion = index < accionesSeleccionadas.length ? accionesSeleccionadas[index] : null;

  return GestureDetector(
    onTap: accion != null ? () => deseleccionarAccion(accion) : null,
    child: Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: accion != null ? Colors.greenAccent.shade100 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${index + 1}º',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                accion ?? '---',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secuencia de Acciones'),
      ),
      body: instruccionesMostradas
          ? Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'Objetivo:\n$objetivo',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('Acciones seleccionadas:', style: TextStyle(fontSize: 16)),
Expanded(
  flex: 2,
  child: GridView.count(
    crossAxisCount: 3,
    padding: const EdgeInsets.all(8),
    childAspectRatio: 1.2,
    children: List.generate(3, (index) => buildAccionSeleccionada(index)),
  ),
),

                const Divider(),
                const Text('Acciones disponibles:', style: TextStyle(fontSize: 16)),
                Expanded(
                  flex: 3,
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(8),
                    childAspectRatio: 3,
                    children: accionesDisponibles.map(buildAccionDisponible).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: accionesSeleccionadas.isNotEmpty ? comprobarSecuencia : null,
                  child: const Text('Comprobar'),
                ),
                const SizedBox(height: 10),
              ],
            )
          : const Center(
              child: Text(
                'Cargando instrucciones...',
                style: TextStyle(fontSize: 18),
              ),
            ),
    );
  }
}

