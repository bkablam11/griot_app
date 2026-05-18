import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'story_detail_page.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VillagePage extends StatefulWidget {
  const VillagePage({super.key});

  @override
  State<VillagePage> createState() => _VillagePageState();
}

class _VillagePageState extends State<VillagePage> {
  final user = FirebaseAuth.instance.currentUser;
  final userService = UserService();

  // Variables de recherche
  String _searchQuery = "";
  String _selectedLang = "Toutes";
  final List<String> _languages = [
    "Toutes",
    "Français",
    "Dioula",
    "Baoulé",
    "Agni",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF8C6239)),
          onPressed: () async {
            await AuthService().signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/',
              ); // Assure-toi d'avoir cette route ou utilise ton code précédent
            }
          },
        ),
        title: Text(
          "GRIOT",
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        // On utilise une Column pour empiler Recherche + Grille
        children: [
          // 1. LA BARRE DE RECHERCHE ET LES LANGUES (Fixe en haut)
          _buildSearchAndFilters(),

          // 2. LA GRILLE DES HISTOIRES (Prend le reste de l'espace)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stories')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                // LOGIQUE DE FILTRAGE (Client-side)
                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? "").toString().toLowerCase();
                  final elder = (data['elderName'] ?? "")
                      .toString()
                      .toLowerCase();
                  final lang = data['language'] ?? "";

                  // On vérifie si ça correspond au texte tapé
                  bool matchesSearch =
                      title.contains(_searchQuery.toLowerCase()) ||
                      elder.contains(_searchQuery.toLowerCase());

                  // On vérifie si ça correspond à la langue choisie
                  bool matchesLang =
                      _selectedLang == "Toutes" || lang == _selectedLang;

                  return matchesSearch && matchesLang;
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 900
                        ? 3
                        : 1,
                    mainAxisSpacing: 25,
                    crossAxisSpacing: 25,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    return _buildStoryCard(
                      context,
                      data,
                      filteredDocs[index].id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET : Barre de recherche et chips de langues
  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white, // Fond blanc pour détacher du gris
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          // Barre de texte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Chercher un récit ou un Griot...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8C6239)),
                filled: true,
                fillColor: const Color(0xFFF5F5F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Liste horizontale des langues
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: ["Toutes", "Français", "Dioula", "Baoulé", "Agni"].map((
                lang,
              ) {
                bool isSelected = _selectedLang == lang;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(lang),
                    selected: isSelected,
                    onSelected: (selected) =>
                        setState(() => _selectedLang = lang),
                    selectedColor: const Color(0xFF8C6239),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET : Carte d'histoire (ton code précédent mis en fonction pour la propreté)
  Widget _buildStoryCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryDetailPage(story: data, docId: docId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  data['imageUrl'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['language']?.toUpperCase() ?? "TRADITION",
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8C6239),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data['title'] ?? "Sans titre",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Par ${data['elderName']}",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${data['likesCount'] ?? 0}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
