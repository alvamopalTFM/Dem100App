const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const axios = require("axios");
const { spawn } = require("child_process");

initializeApp();
const db = getFirestore();

// 🔁 Funciones para cada colección
exports.evaluarNuevoTest_stroop_tests = onDocumentCreated("stroop_tests/{docId}", async (event) => {
  const data = event.data.data();
  if (!data || !data.uid) return;
  try {
    await axios.post("https://api-ml-179104331634.us-central1.run.app/analizar", { uid: data.uid });
  } catch (e) {
    console.error("❌ Error llamando a analizar:", e.message);
  }
});

exports.evaluarNuevoTest_nback_tests = onDocumentCreated("nback_tests/{docId}", async (event) => {
  const data = event.data.data();
  if (!data || !data.uid) return;
  try {
    await axios.post("https://api-ml-179104331634.us-central1.run.app/analizar", { uid: data.uid });
  } catch (e) {
    console.error("❌ Error llamando a analizar:", e.message);
  }
});

exports.evaluarNuevoTest_laberinto_tests = onDocumentCreated("laberinto_tests/{docId}", async (event) => {
  const data = event.data.data();
  if (!data || !data.uid) return;
  try {
    await axios.post("https://api-ml-179104331634.us-central1.run.app/analizar", { uid: data.uid });
  } catch (e) {
    console.error("❌ Error llamando a analizar:", e.message);
  }
});

exports.evaluarNuevoTest_secuencia_acciones_tests = onDocumentCreated("secuencia_acciones_tests/{docId}", async (event) => {
  const data = event.data.data();
  if (!data || !data.uid) return;
  try {
    await axios.post("https://api-ml-179104331634.us-central1.run.app/analizar", { uid: data.uid });
  } catch (e) {
    console.error("❌ Error llamando a analizar:", e.message);
  }
});

exports.evaluarNuevoTest_memoria_secuencial_tests = onDocumentCreated("memoria_secuencial_tests/{docId}", async (event) => {
  const data = event.data.data();
  if (!data || !data.uid) return;
  try {
    await axios.post("https://api-ml-179104331634.us-central1.run.app/analizar", { uid: data.uid });
  } catch (e) {
    console.error("❌ Error llamando a analizar:", e.message);
  }
});

exports.evaluarNuevoTest_categorizacion_rapida_tests = onDocumentCreated("categorizacion_rapida_tests/{docId}", async (event) => {
  const data = event.data.data();
  if (!data || !data.uid) return;
  try {
    await axios.post("https://api-ml-179104331634.us-central1.run.app/analizar", { uid: data.uid });
  } catch (e) {
    console.error("❌ Error llamando a analizar:", e.message);
  }
});

// ✅ Función HTTP que ejecuta el análisis ML
exports.analizar = onRequest(async (req, res) => {
  try {
    const uid = req.body.uid;
    if (!uid) {
      res.status(400).send("UID faltante");
      return;
    }

    const proceso = spawn("python", ["app.py", uid]);

    let resultado = "";
    proceso.stdout.on("data", (data) => {
      resultado += data.toString();
    });

    proceso.stderr.on("data", (data) => {
      console.error(`❌ Error en Python: ${data}`);
    });

    proceso.on("close", (code) => {
      if (code === 0) {
        res.status(200).send(resultado);
      } else {
        res.status(500).send("❌ Fallo ejecutando análisis");
      }
    });

  } catch (err) {
    res.status(500).send("❌ Error general: " + err.message);
  }
});

