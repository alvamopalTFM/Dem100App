import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dem100app/machine_learning/api_ml.dart';

class CategorizacionRapidaPage extends StatefulWidget {
  const CategorizacionRapidaPage({super.key});

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

  final Random random = Random();

  bool juegoIniciado = false;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  final Map<String, List<String>> todasLasCategorias = {
    'Animales': ['Perro', 'Gato', 'León', 'Elefante', 'Tigre', 'Salmón', 'Paloma', 'Gorila'],
    'Frutas': ['Manzana', 'Plátano', 'Uva', 'Naranja', 'Fresa', 'Limón', 'Pera', 'Piña', 'Melón', 'Sandía'],
    'Vehículos': ['Coche', 'Camión', 'Moto', 'Avión', 'Helicoptero', 'Tractor', 'Barco'],
    'Ropa': ['Camiseta', 'Pantalón', 'Zapato', 'Abrigo', 'Sombrero', 'Chaqueta', 'Calcetines'],
    'Herramientas': ['Martillo', 'Destornillador', 'Taladro', 'Llave inglesa', 'Alicate', 'Sierra'],
    'Colores': ['Rojo', 'Azul', 'Verde', 'Amarillo', 'Morado', 'Negro', 'Blanco', 'Naranja'],
  };

  List<String> categoriasSeleccionadas = [];
  Map<String, String> palabrasFiltradas = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seleccionarCategorias();
      _mostrarInstrucciones();
    });
  }

  void _seleccionarCategorias() {
    final todas = todasLasCategorias.keys.toList();
    todas.shuffle();
    categoriasSeleccionadas = todas.take(3).toList();

    palabrasFiltradas = {};
    for (var categoria in categoriasSeleccionadas) {
      for (var palabra in todasLasCategorias[categoria]!) {
        palabrasFiltradas[palabra] = categoria;
      }
    }
    setState(() {});
  }

  void _mostrarInstrucciones() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Instrucciones'),
        content: Text(
          'Clasifica la palabra que aparece tocando la categoría correcta.\n\n'
          'Tienes 60 segundos para clasificar el mayor número posible.\n\n'
          'Categorías activas:\n- ${categoriasSeleccionadas.join('\n- ')}\n\n'
          '¡Empieza cuando pulses OK!',
          style: const TextStyle(fontSize: 16),
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
    final palabrasKeys = palabrasFiltradas.keys.toList();
    String nuevaPalabra;
    do {
      nuevaPalabra = palabrasKeys[random.nextInt(palabrasKeys.length)];
    } while (nuevaPalabra == ultimaPalabraMostrada);

    setState(() {
      palabraActual = nuevaPalabra;
      categoriaCorrecta = palabrasFiltradas[nuevaPalabra]!;
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
    isLoading.value = true;
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('categorizacion_rapida_tests').add({
        'uid': user.uid,
        'email': user.email,
        'aciertos': aciertos,
        'errores': errores,
        'categorias': categoriasSeleccionadas,
        'timestamp': Timestamp.now(),
      });
      await lanzarEvaluacionML();
    }
    isLoading.value = false;

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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: categoriasSeleccionadas.isEmpty
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Tiempo restante: $tiempoRestante s', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                        const SizedBox(height: 40),
                        Text(palabraActual, textAlign: TextAlign.center, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                        const SizedBox(height: 50),
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          alignment: WrapAlignment.center,
                          children: categoriasSeleccionadas.map((categoria) {
                            return ElevatedButton(
                              onPressed: () => _seleccionarCategoria(categoria),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFBBDEFB),
                                foregroundColor: const Color(0xFF0D47A1),
                                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 6,
                              ),
                              child: Text(categoria, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 50),
                        Text('Aciertos: $aciertos    Errores: $errores', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF1565C0))),
                      ],
                    ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, loading, _) {
              if (!loading) return const SizedBox.shrink();
              return Container(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Guardando resultados...', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}


