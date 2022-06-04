import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatting/allConstants/all_constants.dart';

class ChatMessages {
  String idFrom;
  String idTo;
  String timestamp;
  String content;
  Map<String, dynamic>? metadata;
  int type;

  ChatMessages(
      {required this.idFrom,
      required this.idTo,
      required this.timestamp,
      required this.content,
      required this.type,
        this.metadata
      });

  Map<String, dynamic> toJson() {
    return {
      FirestoreConstants.idFrom: idFrom,
      FirestoreConstants.idTo: idTo,
      FirestoreConstants.timestamp: timestamp,
      FirestoreConstants.content: content,
      FirestoreConstants.type: type,
      FirestoreConstants.metadata: metadata,
    };
  }

  factory ChatMessages.fromDocument(DocumentSnapshot documentSnapshot) {
    String idFrom = documentSnapshot.get(FirestoreConstants.idFrom);
    String idTo = documentSnapshot.get(FirestoreConstants.idTo);
    String timestamp = documentSnapshot.get(FirestoreConstants.timestamp);
    String content = documentSnapshot.get(FirestoreConstants.content);
    int type = documentSnapshot.get(FirestoreConstants.type);
    Map<String, dynamic>? metadata = (documentSnapshot.data() as Map)[FirestoreConstants.metadata] as Map<String, dynamic>?;

    return ChatMessages(
        idFrom: idFrom,
        idTo: idTo,
        timestamp: timestamp,
        content: content,
        type: type,
      metadata: metadata
    );
  }
}
