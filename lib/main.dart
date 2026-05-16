import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Ajoute ça
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart'; // <--- POUR SUPABASE

import 'features/home/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Charger les variables d'environnement
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    print("Erreur chargement env: $e");
  }

  // 1. Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Supabase (Utiliser les variables d'env pour la sécurité)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Hive (Offline storage)
  await Hive.initFlutter();
  await Hive.openBox('village_box');
  // Connexion silencieuse au démarrage
  await AuthService().signInAnonymously();

  runApp(const GriotApp());
}

class GriotApp extends StatelessWidget {
  const GriotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F0), // Griot-Bg
        textTheme: GoogleFonts.cormorantGaramondTextTheme(),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F0), // Griot-Bg
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // LOGO LIVRE
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5A5A40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "GRIOT",
              style: GoogleFonts.cormorantGaramond(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 15),

            // CITATION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "\"Un vieillard qui meurt est une bibliothèque qui brûle.\"",
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "— Amadou Hampâté Bâ",
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const Spacer(flex: 1),

            // --- ZONE D'ACTIONS ---

            // 1. BOUTON VISITEUR (ENTRER DANS LE VILLAGE)
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              child: Container(
                width: 260,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF5A5A40), width: 1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  "ENTRER DANS LE VILLAGE",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5A5A40),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 2. BOUTON COLLECTEUR (DEVENIR COLLECTEUR)
            GestureDetector(
              onTap: () async {
                // On vérifie si l'utilisateur est déjà un collecteur Google
                if (auth.isCollector()) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                } else {
                  // Sinon on lance la connexion Google (Conversion Anonyme -> Google)
                  final navigationContext = context;
                  var user = await auth.signInWithGoogle();
                  if (user != null && navigationContext.mounted) {
                    Navigator.push(
                      navigationContext,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(),
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: 260,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A4A35),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "DEVENIR COLLECTEUR",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // PETIT TEXTE EXPLICATIF
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                "En devenant collecteur, vous aidez Robot Girl à préserver notre patrimoine oral.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(flex: 2),

            // FOOTER
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                "PROPULSÉ PAR LYCÉE MODERNE 1 ABOBO • MAI 2026",
                style: GoogleFonts.inter(
                  fontSize: 8,
                  letterSpacing: 1,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
