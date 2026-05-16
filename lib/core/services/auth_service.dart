import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Connexion Anonyme
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      debugPrint("Erreur Anonyme: $e");
      return null;
    }
  }

  // Connexion Google (Code standard stable)
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? currentUser = _auth.currentUser;

      if (currentUser != null && currentUser.isAnonymous) {
        try {
          // TENTATIVE 1 : Lier le compte anonyme au Gmail
          UserCredential result = await currentUser.linkWithCredential(
            credential,
          );
          return result.user;
        } on FirebaseAuthException catch (e) {
          // TENTATIVE 2 : Si le Gmail est déjà utilisé par un autre compte
          if (e.code == 'credential-already-in-use') {
            debugPrint("Le compte existe déjà, simple connexion en cours...");
            UserCredential result = await _auth.signInWithCredential(
              credential,
            );
            return result.user;
          }
          rethrow;
        }
      } else {
        // Connexion directe si pas d'anonyme
        UserCredential result = await _auth.signInWithCredential(credential);
        return result.user;
      }
    } catch (e) {
      debugPrint("Erreur Google: $e");
      return null;
    }
  }

  bool isCollector() {
    User? user = _auth.currentUser;
    if (user == null || user.isAnonymous) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  // --- ACTION : DÉCONNEXION COMPLÈTE ---
  Future<void> signOut() async {
    try {
      await _auth.signOut(); // Déconnexion Firebase
      await _googleSignIn
          .signOut(); // Déconnexion Google (pour pouvoir changer de compte)
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion : $e");
    }
  }
}
