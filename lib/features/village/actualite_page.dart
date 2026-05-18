import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ActualitePage extends StatelessWidget {
  const ActualitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text(
          "VIE DU VILLAGE",
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
        // On écoute maintenant la collection globale des activités
        stream: FirebaseFirestore.instance
            .collection('activities')
            .orderBy('createdAt', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("Le village est calme..."));

          return ListView.builder(
            padding: const EdgeInsets.all(25),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildActivityTile(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> data) {
    bool isRankUp = data['type'] == 'rank_up';

    // Formatage date
    DateTime date = DateTime.parse(data['createdAt']);
    String timeStr = DateFormat('dd MMM, HH:mm').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ICÔNE DYNAMIQUE
          CircleAvatar(
            radius: 22,
            backgroundColor: isRankUp
                ? const Color(0xFFD4AF37)
                : const Color(0xFF8C6239).withOpacity(0.1),
            child: Icon(
              isRankUp ? Icons.military_tech : Icons.menu_book_rounded,
              color: isRankUp ? Colors.white : const Color(0xFF8C6239),
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          // CONTENU
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: Colors.black26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                if (isRankUp)
                  // Message pour la montée en grade
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: data['userName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: " a été élevé au rang de "),
                        TextSpan(
                          text: data['newRank'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8C6239),
                          ),
                        ),
                        const TextSpan(text: " ! Le Village le salue. 👏"),
                      ],
                    ),
                  )
                else
                  // Message pour un nouveau récit
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: data['userName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: " a consigné un nouveau récit : "),
                        TextSpan(
                          text: "\"${data['title']}\"",
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
