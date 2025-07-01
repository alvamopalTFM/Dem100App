import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

Future<void> lanzarEvaluacionML() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final response = await http.post(
      Uri.parse('https://api-ml-179104331634.us-central1.run.app/analizar'),
      headers: {'Content-Type': 'application/json'},
      body: '{"uid": "${user.uid}"}',
    );

    if (response.statusCode == 200) {
      // ignore: avoid_print
      print("ML ejecutado correctamente");
    } else {
      // ignore: avoid_print
      print("Error ML: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    // ignore: avoid_print
    print("Excepción al llamar a la función ML: $e");
  }
}
