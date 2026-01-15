import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

ValueNotifier<ThemeMode> temaGlobal = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Firebase.initializeApp(); } catch (e) { debugPrint("Error: $e"); }
  runApp(const MiSalonApp());
}

class MiSalonApp extends StatelessWidget {
  const MiSalonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaGlobal,
      builder: (context, modoActual, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: modoActual,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFE91E63)),
        darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFE91E63), brightness: Brightness.dark),
        home: const CatalogoPrincipal(),
      ),
    );
  }
}

// --- VISTA PARA AMPLIAR FOTOS ---
class VisorFotos extends StatelessWidget {
  final List fotos;
  final int indiceInicial;
  const VisorFotos({super.key, required this.fotos, required this.indiceInicial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
      body: PhotoViewGallery.builder(
        itemCount: fotos.length,
        builder: (context, index) => PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(fotos[index]),
          minScale: PhotoViewComputedScale.contained,
        ),
        pageController: PageController(initialPage: indiceInicial),
      ),
    );
  }
}

class CatalogoPrincipal extends StatelessWidget {
  const CatalogoPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => _mostrarLogin(context),
          child: const Text("NAIL ART STUDIO")
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFE91E63)),
              child: Center(child: Text("MENÚ", style: TextStyle(color: Colors.white, fontSize: 24))),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Hacer una Pregunta"),
              onTap: () {
                Navigator.pop(context);
                _mostrarPopupPregunta(context);
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref("trabajos").onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) return const Center(child: Text("Cargando catálogo..."));
          Map datos = snapshot.data!.snapshot.value as Map;
          List items = datos.entries.map((e) => {"id": e.key, ...e.value as Map}).toList();

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final ui = items[index];
              List fotos = ui["imagenes"] ?? [ui["imagen"]];
              final PageController controller = PageController();

              return Card(
                margin: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SizedBox(
                      height: 350,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: controller,
                            itemCount: fotos.length,
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => VisorFotos(fotos: fotos, indiceInicial: i))),
                              child: Image.network(fotos[i], fit: BoxFit.cover, width: double.infinity),
                            ),
                          ),
                          if (fotos.length > 1)
                            Positioned(
                              bottom: 10, left: 0, right: 0,
                              child: Center(child: SmoothPageIndicator(controller: controller, count: fotos.length, effect: const ExpandingDotsEffect(activeDotColor: Colors.pink, dotHeight: 10, dotWidth: 10))),
                            ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text(ui["nombre"], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(ui["precio"], style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                      trailing: ElevatedButton.icon(
                        onPressed: () => launchUrl(Uri.parse("https://wa.me/56986257924?text=Hola! Me interesa este diseño: ${ui["nombre"]}")),
                        icon: const Icon(Icons.chat, color: Colors.green),
                        label: const Text("Consultar"),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarPopupPregunta(BuildContext context) {
    TextEditingController m = TextEditingController();
    TextEditingController t = TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Duda para la dueña:", style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(controller: t, decoration: const InputDecoration(hintText: "Tu teléfono/WhatsApp")),
        TextField(controller: m, decoration: const InputDecoration(hintText: "Escribe tu duda...")),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () {
          FirebaseDatabase.instance.ref("preguntas").push().set({
            "mensaje": m.text, "telefono": t.text, "fecha": DateTime.now().toString()
          });
          Navigator.pop(c);
        }, child: const Text("Enviar")),
        const SizedBox(height: 20),
      ]),
    ));
  }

  void _mostrarLogin(BuildContext context) {
    TextEditingController pin = TextEditingController();
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Acceso Dueña"),
      content: TextField(controller: pin, obscureText: true, decoration: const InputDecoration(hintText: "PIN")),
      actions: [TextButton(onPressed: () { if (pin.text == "2026") { Navigator.pop(c); Navigator.push(context, MaterialPageRoute(builder: (c) => const PanelAdmin())); } }, child: const Text("Entrar"))],
    ));
  }
}

class PanelAdmin extends StatefulWidget {
  const PanelAdmin({super.key});
  @override
  State<PanelAdmin> createState() => _PanelAdminState();
}

class _PanelAdminState extends State<PanelAdmin> {
  bool subiendo = false;

  // --- FUNCIÓN PARA EDITAR TRABAJO ---
  void _editarTrabajo(BuildContext context, String id, Map data) {
    TextEditingController nom = TextEditingController(text: data["nombre"]);
    TextEditingController pre = TextEditingController(text: data["precio"]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Diseño"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nom, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: pre, decoration: const InputDecoration(labelText: "Precio")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              FirebaseDatabase.instance.ref("trabajos").child(id).update({
                "nombre": nom.text,
                "precio": pre.text,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Diseño actualizado")));
            }, 
            child: const Text("Guardar Cambios")
          )
        ],
      ),
    );
  }

  Future<void> _subirDesdeGaleria() async {
    final List<XFile> images = await ImagePicker().pickMultiImage();
    if (images.isEmpty) return;

    TextEditingController nom = TextEditingController();
    TextEditingController pre = TextEditingController();

    if (!mounted) return;
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Nuevo Trabajo"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("${images.length} fotos seleccionadas"),
        TextField(controller: nom, decoration: const InputDecoration(hintText: "Nombre")),
        TextField(controller: pre, decoration: const InputDecoration(hintText: "Precio")),
      ]),
      actions: [
        ElevatedButton(onPressed: () async {
          setState(() => subiendo = true);
          Navigator.pop(c);
          
          List<String> linksSubidos = [];
          try {
            for (var img in images) {
              var request = http.MultipartRequest('POST', Uri.parse('https://api.imgbb.com/1/upload?key=37d516874cdb4fb1e250be7f293af619'));
              request.files.add(await http.MultipartFile.fromPath('image', img.path));
              var response = await request.send();
              var responseData = await response.stream.bytesToString();
              var json = jsonDecode(responseData);
              linksSubidos.add(json['data']['url']);
            }

            await FirebaseDatabase.instance.ref("trabajos").push().set({
              "nombre": nom.text, "precio": pre.text, "imagenes": linksSubidos
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ ¡Publicado con éxito!")));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error al subir: $e")));
          } finally {
            setState(() => subiendo = false);
          }
        }, child: const Text("Publicar"))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Panel de Control"),
          bottom: const TabBar(tabs: [Tab(text: "Mensajes"), Tab(text: "Catálogo")]),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: subiendo ? null : _subirDesdeGaleria,
          child: subiendo ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add_a_photo),
        ),
        body: TabBarView(
          children: [
            // PESTAÑA 1: MENSAJES RECIBIDOS
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref("preguntas").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) return const Center(child: Text("No hay mensajes"));
                Map datos = snapshot.data!.snapshot.value as Map;
                return ListView(
                  children: datos.entries.map((e) => Card(
                    child: ListTile(
                      title: Text(e.value["mensaje"]),
                      subtitle: Text("📞 ${e.value["telefono"]}\n${e.value["fecha"]}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => FirebaseDatabase.instance.ref("preguntas").child(e.key).remove(),
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
            // PESTAÑA 2: GESTIÓN DE CATÁLOGO (CON EDICIÓN)
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref("trabajos").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) return const Center(child: Text("Catálogo vacío"));
                Map datos = snapshot.data!.snapshot.value as Map;
                return ListView(
                  children: datos.entries.map((e) {
                    final data = e.value as Map;
                    return ListTile(
                      leading: data["imagenes"] != null 
                          ? Image.network(data["imagenes"][0], width: 50, height: 50, fit: BoxFit.cover) 
                          : const Icon(Icons.image),
                      title: Text(data["nombre"]),
                      subtitle: Text(data["precio"]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue), // BOTÓN PARA EDITAR
                            onPressed: () => _editarTrabajo(context, e.key, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => FirebaseDatabase.instance.ref("trabajos").child(e.key).remove(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}