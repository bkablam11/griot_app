import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/storage_service.dart';
import 'dart:io';
import '../../core/services/ai_service.dart';
import '../home/main_screen.dart';
import 'package:file_picker/file_picker.dart'; // <--- NOUVEAU
import 'dart:typed_data'; // Pour corriger l'erreur 'Uint8List'
import 'package:flutter/foundation.dart'
    show kIsWeb; // Pour corriger l'erreur 'kIsWeb'

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _elderController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  String _selectedLanguage = 'Français';

  late AudioRecorder audioRecorder;
  bool isRecording = false;
  bool isUploading = false;
  String? audioPath;
  Timer? _timer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    audioRecorder.dispose();
    _titleController.dispose();
    _elderController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  // --- NOUVELLE FONCTION : SÉLECTION DE FICHIER ---
  Future<void> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true, // INDISPENSABLE POUR LE WEB (récupère les bytes)
      );
      if (result != null) {
        if (kIsWeb) {
          // Sur Web, on utilise les bytes
          _handleFinalSave(
            path: result.files.single.name,
            bytes: result.files.single.bytes,
          );
        } else {
          // Sur Mobile, on utilise le path
          _handleFinalSave(path: result.files.single.path!);
        }
      }
    } catch (e) {
      debugPrint("Erreur sélection : $e");
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath =
            '${appDocDir.path}/griot_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await audioRecorder.start(const RecordConfig(), path: filePath);
        setState(() {
          isRecording = true;
          audioPath = filePath;
          _recordDuration = 0;
        });
        _timer = Timer.periodic(
          const Duration(seconds: 1),
          (t) => setState(() => _recordDuration++),
        );
      }
    } catch (e) {
      debugPrint("Erreur : $e");
    }
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    final path = await audioRecorder.stop();
    setState(() => isRecording = false);
    if (path != null) _showSaveDialog(path);
  }

  // Ajoute l'argument optionnel Uint8List? bytes
  Future<void> _handleFinalSave({
    required String path,
    Uint8List? bytes,
  }) async {
    setState(() => isUploading = true);

    try {
      String extension = path.split('.').last;
      String fileName =
          "audio_${DateTime.now().millisecondsSinceEpoch}.$extension";

      // ON APPELLE NOTRE NOUVEAU SERVICE UNIVERSEL
      final storageUrl = await StorageService().uploadAudio(
        fileName: fileName,
        localPath: kIsWeb ? null : path,
        fileBytes: bytes,
      );

      if (storageUrl != null) {
        String finalTitle = _titleController.text.isEmpty
            ? "Récit sans titre"
            : _titleController.text;
        String imageUrl =
            "https://image.pollinations.ai/prompt/african_tradition_art?nologo=true";

        try {
          final aiResult = await AIService().enrichirRecit(
            _summaryController.text,
          );
          if (aiResult != null) {
            finalTitle = aiResult['titre'] ?? finalTitle;
            final String encodedPrompt = Uri.encodeComponent(
              aiResult['prompt'] ?? "African art",
            );
            // On ajoute un seed aléatoire pour éviter le cache et les blocages 403
            final int seed = DateTime.now().millisecondsSinceEpoch;
            final String imageUrl =
                "https://image.pollinations.ai/prompt/${encodedPrompt}?nologo=true&seed=$seed&width=1024&height=1024";
          }
        } catch (e) {
          debugPrint("L'IA a échoué : $e");
        }

        final String timestamp = DateTime.now().toIso8601String();
        final storyData = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': finalTitle,
          'elderName': _elderController.text,
          'summary': _summaryController.text,
          'language': _selectedLanguage,
          'audioUrl': storageUrl,
          'imageUrl': imageUrl,
          'createdAt': timestamp,
          'likesCount': 0,
        };

        await FirebaseFirestore.instance.collection('stories').add(storyData);
        await Hive.box('village_box').add(storyData);

        if (mounted) {
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF5A5A40),
              content: Text("Parole sauvegardée avec succès."),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur complète : $e");
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _showSaveDialog(String path) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF5F5F0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ), // Style Brutaliste
            title: Text(
              "Vérification",
              style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            content: isUploading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF8C6239)),
                      const SizedBox(height: 20),
                      Text(
                        "Le Village prépare votre place...",
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ],
                  )
                : Text(
                    "Voulez-vous confier le récit de ${_elderController.text} au Village ?",
                    style: GoogleFonts.inter(),
                  ),
            actions: isUploading
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "REPRENDRE",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141414),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _handleFinalSave(path: path),
                      child: const Text("CONFIRMER"),
                    ),
                  ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text(
          "COLLECTE",
          style: GoogleFonts.inter(
            fontSize: 11,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              "L'Oracle",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            Text(
              "Capturez la sagesse des anciens",
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
            ),
            const SizedBox(height: 40),

            // --- SECTION FORMULAIRE ---
            _buildCustomField(
              "NOM DE L'ANCIEN",
              _elderController,
              hint: "Papi Konan...",
            ),
            _buildCustomField(
              "TITRE PROVISOIRE",
              _titleController,
              hint: "La tortue et le lièvre...",
            ),

            // Sélecteur de langue plus stylé
            Text(
              "LANGUE",
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: const Color(0xFF8C6239),
              ),
            ),
            DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              underline: Container(height: 1, color: Colors.black12),
              items: ['Français', 'Dioula', 'Baoulé', 'Agni']
                  .map(
                    (l) => DropdownMenuItem(
                      value: l,
                      child: Text(l, style: GoogleFonts.inter(fontSize: 15)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedLanguage = v!),
            ),

            const SizedBox(height: 30),
            _buildCustomField(
              "RÉSUMÉ DU RÉCIT",
              _summaryController,
              hint: "De quoi parle cette histoire ?",
              maxLines: 3,
            ),

            const SizedBox(height: 50),

            // --- SECTION ENREGISTREMENT & UPLOAD ---
            Center(
              child: Column(
                children: [
                  Text(
                    _formatDuration(_recordDuration),
                    style: GoogleFonts.inter(
                      fontSize: 50,
                      fontWeight: FontWeight.w100,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // BOUTON UPLOAD FICHIER (Gauche)
                      if (!isRecording)
                        IconButton(
                          onPressed: pickAudioFile,
                          icon: const Icon(
                            Icons.file_upload_outlined,
                            color: Color(0xFF8C6239),
                            size: 30,
                          ),
                        ),

                      const SizedBox(width: 20),

                      // BOUTON MICRO CENTRAL
                      GestureDetector(
                        onTap: isRecording ? stopRecording : startRecording,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isRecording) const _PulseAnimation(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isRecording
                                    ? Colors.red
                                    : const Color(0xFF141414),
                                boxShadow: [
                                  BoxShadow(
                                    color: isRecording
                                        ? Colors.red.withAlpha(77)
                                        : Colors.black26,
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isRecording
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // ESPACE VIDE POUR L'ÉQUILIBRE (ou autre icône à droite)
                      if (!isRecording) const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    isRecording
                        ? "L'ANCIEN PARLE..."
                        : "ENREGISTRER OU IMPORTER",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      color: isRecording ? Colors.red : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: const Color(0xFF8C6239),
            ),
          ),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.inter(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black12),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black12),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF8C6239)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pour l'animation de pulsation du micro
class _PulseAnimation extends StatefulWidget {
  const _PulseAnimation();

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.5, end: 0.0).animate(_controller),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.8).animate(_controller),
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
