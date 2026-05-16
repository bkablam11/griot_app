import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/storage_service.dart';
import 'dart:io' show Directory, File;
import '../../core/services/ai_service.dart';
import '../home/main_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  // --- SÉLECTION DE FICHIER (Compatible Web/Mobile) ---
  Future<void> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
        // On passe le nom et les bytes au dialogue
        _showSaveDialog(
          path: result.files.single.name,
          bytes: result.files.single.bytes,
        );
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

  // --- ENREGISTREMENT (Compatible Web/Mobile) ---
  Future<void> startRecording() async {
    try {
      if (await audioRecorder.hasPermission()) {
        String? filePath;

        if (!kIsWeb) {
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          filePath =
              '${appDocDir.path}/griot_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }

        // Sur Web, path est ignoré par le package record, il crée un Blob
        await audioRecorder.start(const RecordConfig(), path: filePath ?? '');

        setState(() {
          isRecording = true;
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
    if (path != null) {
      _showSaveDialog(path: path);
    }
  }

  // --- LOGIQUE DE SAUVEGARDE FINALE ---
  Future<void> _handleFinalSave({
    required String path,
    Uint8List? bytes,
  }) async {
    setState(() => isUploading = true);

    try {
      String extension = path.contains('.') ? path.split('.').last : 'm4a';
      String fileName =
          "audio_${DateTime.now().millisecondsSinceEpoch}.$extension";

      // Appel au service de stockage (ton service universel)
      final storageUrl = await StorageService().uploadAudio(
        fileName: fileName,
        localPath: kIsWeb ? null : path,
        fileBytes: bytes,
      );

      if (storageUrl != null) {
        String finalTitle = _titleController.text.isEmpty
            ? "Récit sans titre"
            : _titleController.text;
        String finalImageUrl =
            "https://image.pollinations.ai/prompt/african_art?nologo=true";

        try {
          final aiResult = await AIService().enrichirRecit(
            _summaryController.text,
          );
          if (aiResult != null) {
            finalTitle = aiResult['titre'] ?? finalTitle;
            final String encodedPrompt = Uri.encodeComponent(
              aiResult['prompt'] ?? "African art",
            );
            finalImageUrl =
                "https://image.pollinations.ai/prompt/$encodedPrompt?nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}";
          }
        } catch (e) {
          debugPrint("IA Error: $e");
        }

        final storyData = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': finalTitle,
          'elderName': _elderController.text,
          'summary': _summaryController.text,
          'language': _selectedLanguage,
          'audioUrl': storageUrl,
          'imageUrl': finalImageUrl,
          'createdAt': DateTime.now().toIso8601String(),
          'likesCount': 0,
        };

        await FirebaseFirestore.instance.collection('stories').add(storyData);
        await Hive.box('village_box').add(storyData);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur complète : $e");
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _showSaveDialog({required String path, Uint8List? bytes}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF5F5F0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              "Consigner la parole",
              style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold),
            ),
            content: isUploading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF8C6239)),
                      const SizedBox(height: 20),
                      Text(
                        "L'IA sublime le récit...",
                        style: GoogleFonts.inter(),
                      ),
                    ],
                  )
                : Text("Voulez-vous confier cette sagesse au Village ?"),
            actions: isUploading
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ANNULER"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF141414),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _handleFinalSave(path: path, bytes: bytes),
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
      body: Center(
        // On centre tout pour le Web
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Empêche l'étirement sur PC
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "L'Oracle",
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  "Capturez la sagesse des anciens",
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black45),
                ),
                const SizedBox(height: 40),

                _buildCustomField(
                  "NOM DE L'ANCIEN",
                  _elderController,
                  hint: "Papi ou Mami...",
                ),
                _buildCustomField(
                  "TITRE DU RÉCIT",
                  _titleController,
                  hint: "La légende de...",
                ),

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
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLanguage = v!),
                ),

                const SizedBox(height: 30),
                _buildCustomField(
                  "RÉSUMÉ DU RÉCIT",
                  _summaryController,
                  hint: "L'IA utilisera ce texte pour illustrer l'histoire.",
                  maxLines: 3,
                ),

                const SizedBox(height: 60),

                // --- ZONE DE CAPTURE ---
                Center(
                  child: Column(
                    children: [
                      Text(
                        _formatDuration(_recordDuration),
                        style: GoogleFonts.inter(
                          fontSize: 60,
                          fontWeight: FontWeight.w100,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // BOUTON IMPORTER
                          if (!isRecording)
                            _buildActionButton(
                              Icons.file_upload_outlined,
                              pickAudioFile,
                            ),

                          const SizedBox(width: 30),

                          // BOUTON MICRO AVEC PULSATION
                          GestureDetector(
                            onTap: isRecording ? stopRecording : startRecording,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isRecording) const _PulseAnimation(),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRecording
                                        ? Colors.red
                                        : const Color(0xFF141414),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isRecording
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 45,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 30),
                          if (!isRecording) const SizedBox(width: 45),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Text(
                        isRecording
                            ? "L'ANCIEN PARLE..."
                            : "DÉMARRER LA COLLECTE",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, color: const Color(0xFF8C6239), size: 24),
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
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black12, fontSize: 14),
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
      opacity: Tween(begin: 0.6, end: 0.0).animate(_controller),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 2.0).animate(_controller),
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
