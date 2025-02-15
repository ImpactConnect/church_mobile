import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/community_post.dart';
import '../models/community_comment.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs;
  
  CommunityService(this._prefs);

  // Check if user is verified member
  Future<bool> isVerifiedMember() async {
    return _prefs.getBool('is_verified_member') ?? false;
  }

  // Verify phone number against members collection
  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('members')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        final member = result.docs.first;
        // Store member info locally
        await _prefs.setBool('is_verified_member', true);
        await _prefs.setString('member_id', member.id);
        await _prefs.setString('member_name', member['name']);
        await _prefs.setString('member_phone', phoneNumber);
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying phone number: $e');
      return false;
    }
  }

  // Get current member info
  Map<String, String> getCurrentMember() {
    return {
      'id': _prefs.getString('member_id') ?? '',
      'name': _prefs.getString('member_name') ?? '',
      'phone': _prefs.getString('member_phone') ?? '',
    };
  }

  // Create new post
  Future<void> createPost(String content) async {
    try {
      final member = getCurrentMember();
      await _firestore.collection('community_posts').add({
        'content': content,
        'authorId': member['id'],
        'authorName': member['name'],
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
      });
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Get posts stream
  Stream<List<CommunityPost>> getPosts() {
    return _firestore
        .collection('community_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList());
  }

  // Like/Unlike post
  Future<void> toggleLike(String postId) async {
    try {
      final member = getCurrentMember();
      final likeRef = _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('likes')
          .doc(member['id']);

      final likeDoc = await likeRef.get();
      
      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await _firestore.collection('community_posts').doc(postId).update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'memberId': member['id'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('community_posts').doc(postId).update({
          'likesCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // Get comments for a post
  Stream<List<CommunityComment>> getComments(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityComment.fromFirestore(doc))
            .toList());
  }

  // Add comment to a post
  Future<void> addComment(String postId, String content) async {
    try {
      final member = getCurrentMember();
      final batch = _firestore.batch();
      
      // Create comment
      final commentRef = _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments')
          .doc();
          
      batch.set(commentRef, {
        'postId': postId,
        'content': content,
        'authorId': member['id'],
        'authorName': member['name'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update post comment count
      final postRef = _firestore.collection('community_posts').doc(postId);
      batch.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Check if post is liked by current user
  Future<bool> isPostLiked(String postId) async {
    try {
      final member = getCurrentMember();
      final likeDoc = await _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('likes')
          .doc(member['id'])
          .get();
          
      return likeDoc.exists;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }
}
