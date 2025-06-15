import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dem100app/auth.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({Key? key}) : super(key: key);

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    final email = _controllerEmail.text.trim();
    final password = _controllerPassword.text;

    setState(() => errorMessage = '');

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Por favor, complete todos los campos.');
      return;
    }

    if (password.length < 6) {
      setState(() => errorMessage = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    try {
      await Auth().signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = 'El correo o la contraseña son incorrectos';
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    final email = _controllerEmail.text.trim();
    final password = _controllerPassword.text;

    setState(() => errorMessage = '');

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Por favor, complete todos los campos.');
      return;
    }

    if (password.length < 6) {
      setState(() => errorMessage = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    try {
      await Auth().createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'El correo ya está en uso.';
        } else {
          errorMessage = 'Error al registrar usuario.';
        }
      });
    }
  }

  Widget _entryField(String label, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.lightBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _errorMessage() {
    if (errorMessage == '') return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        errorMessage ?? '',
        style: const TextStyle(color: Colors.red, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _submitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.lightBlueAccent,
      ),
      onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
      child: Text(
        isLogin ? 'Iniciar sesión' : 'Registrarse',
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _loginOrRegisterButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          isLogin = !isLogin;
          errorMessage = '';
        });
      },
      child: Text(
        isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión',
        style: const TextStyle(fontSize: 14, color: Colors.blue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Logo
              SizedBox(
                height: 260,
                child: Image.asset('assets/imagenes/logo.png'),
              ),

              const SizedBox(height: 30),

              // Campos de entrada
              _entryField('Correo electrónico', _controllerEmail),
              _entryField('Contraseña', _controllerPassword, obscure: true),

              _errorMessage(),
              const SizedBox(height: 10),

              _submitButton(),
              const SizedBox(height: 10),
              _loginOrRegisterButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}