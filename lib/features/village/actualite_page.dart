import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'story_detail_page.dart';

class ActualitePage extends StatelessWidget {
  const ActualitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text(
          "FILS D'ACTUALITÉ",
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stories')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text("Le village est calme pour le moment..."),
            );
          }

          // --- LOGIQUE POUR TROUVER LE TOP RÉCIT (Sans l'erreur de type) ---
          DocumentSnapshot? topStory;
          int maxLikes = -1;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final int likes = data['likesCount'] ?? 0;
            if (likes > maxLikes) {
              maxLikes = likes;
              topStory = doc;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (topStory != null) ...[
                _buildSectionTitle("À LA UNE"),
                _buildTopCard(context, topStory),
                const SizedBox(height: 40),
              ],
              _buildSectionTitle("DÉPÊCHES DU VILLAGE"),
              ...docs.map((doc) => _buildActivityItem(context, doc)),
              const SizedBox(height: 50),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFF8C6239),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryDetailPage(story: data, docId: doc.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFD4AF37), size: 18),
                const SizedBox(width: 8),
                Text(
                  "LE RÉCIT LE PLUS HONORÉ",
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              data['title'] ?? "",
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 14),
                const SizedBox(width: 5),
                Text(
                  "${data['likesCount'] ?? 0} j'aime",
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime date = DateTime.now();
    try {
      if (data['createdAt'] is Timestamp) {
        date = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        date = DateTime.parse(data['createdAt']);
      }
    } catch (_) {}

    String timeStr = DateFormat('dd MMM, HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const Icon(Icons.circle, size: 10, color: Color(0xFF8C6239)),
              Container(width: 1, height: 50, color: Colors.black12),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Nouveau récit : ${data['title']}",
                  style: GoogleFonts.inter(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StoryDetailPage(story: data, docId: doc.id),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                  ),
                  child: Text(
                    "DÉCOUVRIR →",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF5A5A40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
