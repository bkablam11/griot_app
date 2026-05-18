import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/user_service.dart';
import '../../core/models/rank_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 1. On prépare les services et les streams
  final userService = UserService();
  final user = FirebaseAuth.instance.currentUser;

  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  late Stream<int> _likesStream;
  late Stream<QuerySnapshot> _myStoriesStream; // ✅ On ajoute celui-là

  @override
  void initState() {
    super.initState();
    // 2. On initialise les streams ICI pour qu'ils ne changent plus jamais
    _userStream = userService.getUserProfile();
    _likesStream = userService.getTotalLikesStream(user?.uid ?? "");
    // ✅ On prépare la liste des histoires une seule fois
    _myStoriesStream = FirebaseFirestore.instance
        .collection('stories')
        .where('collectorId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, snapshot) {
          // Gestion des états de chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8C6239)),
            );
          }

          final userData = snapshot.data?.data() ?? {};
          final int storyCount = userData['storiesCount'] ?? 0;
          final rank = RankData.getRank(storyCount);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // HEADER : STYLE DASHBOARD
              SliverAppBar(
                expandedHeight: 160,
                backgroundColor: const Color(0xFF141414),
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "TABLEAU DE BORD",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 3,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION RANG AVEC ICÔNE ANIMÉE
                      Center(
                        child: Column(
                          children: [
                            Text(
                              rank.icon,
                              style: const TextStyle(fontSize: 70),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              rank.name.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF8C6239),
                                letterSpacing: 2,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              "VOTRE STATUT ACTUEL",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.black26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // STATS DYNAMIQUES
                      Row(
                        children: [
                          _buildStatCard(
                            "RÉCITS",
                            storyCount.toString(),
                            Icons.mic_none,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: StreamBuilder<int>(
                              stream: _likesStream,
                              builder: (context, likeSnap) {
                                return _buildStatCard(
                                  "HONNEURS",
                                  (likeSnap.data ?? 0).toString(),
                                  Icons.favorite_border,
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 50),
                      Text(
                        "VOS DERNIERS TRÉSORS",
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // LISTE DES HISTOIRES
                      StreamBuilder<QuerySnapshot>(
                        stream: _myStoriesStream,
                        builder: (context, storySnap) {
                          if (!storySnap.hasData) return const SizedBox();
                          final docs = storySnap.data!.docs;

                          if (docs.isEmpty) {
                            return const Text(
                              "Aucun récit pour le moment.",
                              style: TextStyle(color: Colors.black38),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final story =
                                  docs[index].data() as Map<String, dynamic>;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.03),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    story['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    story['language'],
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "${story['likesCount'] ?? 0}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 80),
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

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8C6239)),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
