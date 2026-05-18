import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ✅ 1. Logique des Rangs (Inchangée, elle est parfaite)
  String getRank(int count) {
    if (count >= 50) return "Griot d'Or 👑";
    if (count >= 10) return "Gardien du Savoir 🛡️";
    if (count >= 3) return "Messager du Village ✉️";
    return "Apprenti Griot 🌱";
  }

  // ✅ 2. Récupérer le profil (Unique et typé)
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _db.collection('users').doc(user.uid).snapshots();
  }

  // ✅ 3. Total des Likes en temps réel (La source de vérité pour le Dashboard)
  // Cette fonction évite d'avoir à stocker 'totalLikes' manuellement
  Stream<int> getTotalLikesStream(String userId) {
    if (userId.isEmpty) return Stream.value(0);

    return _db
        .collection('stories')
        .where('collectorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.fold<int>(0, (sum, doc) {
            final data = doc.data();
            return sum + (data['likesCount'] as int? ?? 0);
          });
        });
  }
}
