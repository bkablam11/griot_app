import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/storage_service.dart';
import 'dart:io' show Directory;
import '../../core/services/ai_service.dart';
import '../home/main_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart'
    as http; // <--- AJOUTE ÇA (flutter pub add http)

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

  Future<void> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true,
      );
      if (result != null) {
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

  Future<void> startRecording() async {
    try {
      if (await audioRecorder.hasPermission()) {
        String? filePath;
        if (!kIsWeb) {
          final Directory appDocDir = await getApplicationDocumentsDirectory();
          filePath =
              '${appDocDir.path}/griot_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
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

  // --- LOGIQUE DE SAUVEGARDE UNIVERSELLE ---
  Future<void> _handleFinalSave({
    required String path,
    Uint8List? bytes,
  }) async {
    setState(() => isUploading = true);

    try {
      Uint8List? finalBytes = bytes;

      // CORRECTIF WEB : Si on a enregistré (path commence par blob), on télécharge les bytes
      if (kIsWeb && bytes == null && path.startsWith('blob:')) {
        final response = await http.get(Uri.parse(path));
        finalBytes = response.bodyBytes;
      }

      String fileName = "audio_${DateTime.now().millisecondsSinceEpoch}.m4a";

      final storageUrl = await StorageService().uploadAudio(
        fileName: fileName,
        localPath: kIsWeb ? null : path,
        fileBytes: finalBytes,
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
              aiResult['prompt'] ?? "African traditional art",
            );
            finalImageUrl =
                "https://image.pollinations.ai/prompt/$encodedPrompt?nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}";
          }
        } catch (e) {
          debugPrint("IA Error: $e");
        }

        final storyData = {
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
                        "Le Village se prépare...",
                        style: GoogleFonts.inter(),
                      ),
                    ],
                  )
                : const Text("Voulez-vous confier cette sagesse au Village ?"),
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
                      onPressed: () async {
                        // 1. On force l'affichage du chargement DANS le dialogue
                        setDialogState(() {
                          isUploading = true;
                        });

                        // 2. On lance la sauvegarde réelle
                        await _handleFinalSave(path: path, bytes: bytes);

                        // Note: Le Navigator.pushAndRemoveUntil à l'intérieur de
                        // _handleFinalSave fermera automatiquement ce dialogue.
                      },
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
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "L'Oracle",
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
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
                  maxLines: 3,
                ),
                const SizedBox(height: 50),
                Center(
                  child: Column(
                    children: [
                      Text(
                        _formatDuration(_recordDuration),
                        style: GoogleFonts.inter(
                          fontSize: 60,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isRecording)
                            _buildActionButton(
                              Icons.file_upload_outlined,
                              pickAudioFile,
                            ), // L'icône fixée ici
                          const SizedBox(width: 30),
                          GestureDetector(
                            onTap: isRecording ? stopRecording : startRecording,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isRecording) const _PulseAnimation(),
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRecording
                                        ? Colors.red
                                        : const Color(0xFF141414),
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
                          const SizedBox(width: 30),
                          if (!isRecording) const SizedBox(width: 48),
                        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48,
        height: 48, // Taille fixe pour garantir la visibilité
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
        child: Center(
          // On centre l'icône
          child: Icon(icon, color: const Color(0xFF8C6239), size: 24),
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
            decoration: InputDecoration(
              hintText: hint,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black12),
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
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
