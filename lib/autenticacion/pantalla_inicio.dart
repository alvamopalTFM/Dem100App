import 'package:dem100app/minijuegos/laberinto.dart';
import 'package:dem100app/minijuegos/secuencia_acciones.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dem100app/auth.dart';
import 'package:dem100app/minijuegos/test_stroop.dart';
import 'package:dem100app/minijuegos/n_back.dart';
import 'package:dem100app/minijuegos/memoria_secuencial.dart';
import 'package:dem100app/minijuegos/categorizacion_rapida.dart';
import 'package:dem100app/machine_learning/verificar_juegos.dart';


class PantallaInicio extends StatelessWidget {
  PantallaInicio({super.key});

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Cerrar Sesión'),
    );
  }

  Widget _resultadoMLButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => verificarYMostrarResultado(context),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
      child: const Text('Ver resultado cognitivo'),
    );
  }

  Widget buildGameButton(BuildContext context, String imageName, String label, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/imagenes/$imageName',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3E0),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 30,
                children: [
                  buildGameButton(context, 'test_stroop.png', 'Test de Stroop', const TestStroopPage()),
                  buildGameButton(context, 'nback.png', 'Test N-Back', const TestNBackPage()),
                  buildGameButton(context, 'laberinto.png', 'Laberinto', const LaberintoPage()),
                  buildGameButton(context, 'secuencia.png', 'Secuencia', const SecuenciaAccionesPage()),
                  buildGameButton(context, 'memoria.png', 'Memoria', const MemoriaSecuencialPage()),
                  buildGameButton(context, 'categorizacion.png', 'Categorización', const CategorizacionRapidaPage()),
                ],
              ),
              _resultadoMLButton(context),
              const SizedBox(height: 10),
              _signOutButton(),
            ],
          ),
        ),
      ),
    );
  }
}



