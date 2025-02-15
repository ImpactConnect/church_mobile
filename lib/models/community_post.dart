import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  
  CommunityPost({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
    };
  }
}
