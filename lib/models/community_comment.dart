import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  
  CommunityComment({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  factory CommunityComment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
