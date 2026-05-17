import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StoryDetailPage extends StatefulWidget {
  final Map<String, dynamic> story;
  final String docId;

  const StoryDetailPage({super.key, required this.story, required this.docId});

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  late AudioPlayer player;
  bool isPlaying = false;
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // Variables pour le décompte en temps réel
  Timer? _timer;
  String _timeLeft = "";

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
    });

    // Lancer le timer pour le décompte visuel (si besoin)
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft = _getTimeUntilMidnight();
        });
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    _commentController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- FONCTION : CALCUL DU TEMPS RESTANT JUSQU'À MINUIT ---
  String _getTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final difference = midnight.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    return "${hours}h ${minutes}m ${seconds}s";
  }

  // --- ACTION : LIKER LE RÉCIT (Vote unique par jour) ---
  Future<void> _likeStory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final voteDocRef = FirebaseFirestore.instance
        .collection('stories')
        .doc(widget.docId)
        .collection('votes')
        .doc(user.uid);

    try {
      final voteDoc = await voteDocRef.get();

      // Vérification si déjà voté aujourd'hui
      if (voteDoc.exists && voteDoc.data()?['lastVotedDate'] == today) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF141414),
              content: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Déjà honoré aujourd'hui. Nouveau vote dans : ${_getTimeUntilMidnight()}",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return;
      }

      // Calcul des points (Certifié si Gmail)
      bool isCertified = !user.isAnonymous;
      Map<String, dynamic> updates = {'likesCount': FieldValue.increment(1)};
      if (isCertified) {
        updates['certifiedCount'] = FieldValue.increment(1);
      }

      // Mise à jour Firestore
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(widget.docId)
          .update(updates);
      await voteDocRef.set({
        'lastVotedDate': today,
        'isCertified': isCertified,
        'userId': user.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Votre respect a été consigné au Village."),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur vote : $e");
    }
  }

  // --- ACTION : COMMENTER LE RÉCIT ---
  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    String name = "Un auditeur";

    if (user != null && !user.isAnonymous) {
      name = user.displayName ?? user.email ?? "Collecteur";
    }

    await FirebaseFirestore.instance
        .collection('stories')
        .doc(widget.docId)
        .collection('comments')
        .add({
          'text': _commentController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'userName': name,
        });

    _commentController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          final liveData =
              snapshot.data?.data() as Map<String, dynamic>? ?? widget.story;
          final int likesCount = liveData['likesCount'] ?? 0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 450,
                backgroundColor: const Color(0xFF141414),
                leading: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: widget.docId,
                    child: Image.network(
                      liveData['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveData['language']?.toUpperCase() ?? "TRADITION",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          letterSpacing: 3,
                          color: const Color(0xFF8C6239),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        liveData['title'] ?? "Sans titre",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Une parole de ${liveData['elderName']}",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // BOUTON AUDIO
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            if (isPlaying) {
                              await player.pause();
                            } else {
                              await player.play(
                                UrlSource(liveData['audioUrl']),
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: isPlaying
                                  ? const Color(0xFF8C6239)
                                  : const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isPlaying ? "PAUSE" : "ÉCOUTER LE SAGE",
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                      const Divider(color: Colors.black12),
                      const SizedBox(height: 30),

                      // RÉCIT
                      Text(
                        "LE RÉCIT",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: Colors.black26,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        liveData['summary'] ?? "",
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          height: 1.7,
                          color: const Color(0xFF141414),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // --- ZONE D'HONNEUR AVEC DÉCOMPTE ---
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('stories')
                            .doc(widget.docId)
                            .collection('votes')
                            .doc(currentUser?.uid)
                            .snapshots(),
                        builder: (context, voteSnapshot) {
                          final String today = DateFormat(
                            'yyyy-MM-dd',
                          ).format(DateTime.now());
                          bool hasVotedToday = false;
                          if (voteSnapshot.hasData &&
                              voteSnapshot.data!.exists) {
                            hasVotedToday =
                                voteSnapshot.data!['lastVotedDate'] == today;
                          }

                          return Row(
                            children: [
                              GestureDetector(
                                onTap: _likeStory,
                                child: Column(
                                  children: [
                                    Icon(
                                      hasVotedToday
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                      size: 35,
                                    ),
                                    const SizedBox(height: 5),
                                    if (hasVotedToday) ...[
                                      Text(
                                        "PROCHAIN VOTE DANS",
                                        style: GoogleFonts.inter(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black38,
                                        ),
                                      ),
                                      Text(
                                        _timeLeft,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF8C6239),
                                        ),
                                      ),
                                    ] else ...[
                                      Text(
                                        "$likesCount J'AIME",
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.black38,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "LAISSER UNE TRACE",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 25),

                      // COMMENTAIRES
                      TextField(
                        controller: _commentController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Rendez hommage à cette parole...",
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            onPressed: _sendComment,
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF8C6239),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // LISTE DES COMMENTAIRES
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('stories')
                            .doc(widget.docId)
                            .collection('comments')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, commentSnapshot) {
                          if (!commentSnapshot.hasData) return const SizedBox();
                          final comments = commentSnapshot.data!.docs;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(128),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment['userName'],
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                        color: const Color(0xFF8C6239),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      comment['text'],
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
