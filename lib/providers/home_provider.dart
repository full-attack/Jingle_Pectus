import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatting/allConstants/all_constants.dart';

class HomeProvider {
  final FirebaseFirestore firebaseFirestore;

  HomeProvider({required this.firebaseFirestore});

  Future<void> updateFirestoreData(
      String collectionPath, String path, Map<String, dynamic> updateData) {
    return firebaseFirestore
        .collection(collectionPath)
        .doc(path)
        .update(updateData);
  }

  Stream<QuerySnapshot> getFirestoreData(
      String collectionPath, int limit, String? textSearch) {
    if (textSearch?.isNotEmpty == true) {
      return firebaseFirestore
          .collection(collectionPath)
          .orderBy(FirestoreConstants.displayName)
          .where(FirestoreConstants.displayName, isGreaterThanOrEqualTo: textSearch)
          .where(FirestoreConstants.displayName, isLessThanOrEqualTo: textSearch! + "\uf8ff")
          .limit(limit)
          .snapshots();
    } else {
      return firebaseFirestore
          .collection(collectionPath)
          .limit(limit)
          .snapshots();
    }
  }
}
