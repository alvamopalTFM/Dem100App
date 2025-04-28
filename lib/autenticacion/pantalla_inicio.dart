import 'package:dem100app/minijuegos/laberinto.dart';
import 'package:dem100app/minijuegos/secuencia_acciones.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dem100app/auth.dart';
import 'package:dem100app/minijuegos/test_stroop.dart';
import 'package:dem100app/minijuegos/n_back.dart';
import 'package:dem100app/minijuegos/laberinto.dart';

class PantallaInicio extends StatelessWidget {
  PantallaInicio({Key? key}) : super(key: key);

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _title() {
    return const Text('Dem100App');
  }

  Widget _userUid() {
    return Text(user?.email ?? 'email');
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Cerrar Sesion'),
    );
  }

  Widget _stroopTestButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TestStroopPage()),
        );
      },
      child: const Text('Test de Stroop'),
    );
  }

  Widget _nBackButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TestNBackPage()),
        );
      },
      child: const Text('Test de N-Back'),
    );
  }

    Widget laberintoButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LaberintoPage()),
        );
      },
      child: const Text('Laberinto'),
    );
  }

  Widget accionesButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SecuenciaAccionesPage()),
        );
      },
      child: const Text('Secuencia de acciones'),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userUid(),
            const SizedBox(height: 20),
            _stroopTestButton(context),
            const SizedBox(height: 20),
            _signOutButton(),
            const SizedBox(height: 20),
            _nBackButton(context),
            const SizedBox(height: 20),
            laberintoButton(context),
            const SizedBox(height: 20),
            accionesButton(context),
          ],
        ),
      ),
    );
  }
}
