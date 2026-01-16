import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:url_launcher/url_launcher.dart';

class AsistenteIA extends StatefulWidget {
  const AsistenteIA({super.key});

  @override
  State<AsistenteIA> createState() => _AsistenteIAState();
}

class _AsistenteIAState extends State<AsistenteIA> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _mensajes = [];
  bool _cargando = false;

  // --- CONFIGURACIÓN DE GEMINI ---
  final model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: 'AIzaSyDHzHCyir3p0_n-OuD2L1tiu9-UuhV3OUk', 
    systemInstruction: Content.system(
      "Eres la asistente experta de Nail Art Studio. Tu objetivo es asesorar a las clientas sobre diseños de uñas. "
      "Si la clienta elige un servicio, pídele amablemente su nombre y número de WhatsApp. "
      "Al final, ofrece enviar la propuesta a la dueña por WhatsApp. "
      "Solo habla de temas de manicura y belleza del salón."
    ),
  );

  void _enviarMensaje() async {
    if (_controller.text.isEmpty) return;
    String usuarioMsg = _controller.text;
    setState(() {
      _mensajes.add({"rol": "usuario", "texto": usuarioMsg});
      _cargando = true;
    });
    _controller.clear();

    try {
      final content = [Content.text(usuarioMsg)];
      final response = await model.generateContent(content);
      
      setState(() {
        _mensajes.add({"rol": "ia", "texto": response.text ?? "Lo siento, no pude procesar eso."});
      });
    } catch (e) {
      setState(() {
        _mensajes.add({"rol": "ia", "texto": "Error de conexión. Revisa tu API Key."});
      });
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Asistente Nail Art")), // Quitamos el "Beta"
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _mensajes.length,
              itemBuilder: (context, i) {
                bool esIA = _mensajes[i]["rol"] == "ia";
                return Align(
                  alignment: esIA ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esIA ? Colors.pink[50] : Colors.pink[400],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _mensajes[i]["texto"]!,
                      style: TextStyle(color: esIA ? Colors.black : Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_cargando) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Pregúntale a la experta..."),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.pink), onPressed: _enviarMensaje),
              ],
            ),
          ),
          // MODIFICACIÓN: El botón solo aparece si el último mensaje es de la IA
          if (_mensajes.isNotEmpty && _mensajes.last["rol"] == "ia")
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton.icon(
                onPressed: () {
                  String resumen = _mensajes.last["texto"]!;
                  launchUrl(Uri.parse("https://wa.me/56986257924?text=${Uri.encodeComponent("¡Hola! Tengo una propuesta de la IA: $resumen")}"));
                },
                icon: const Icon(Icons.chat),
                label: const Text("Enviar propuesta a la dueña"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}