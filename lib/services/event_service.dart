import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../utils/toast_utils.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Get upcoming events
  Future<List<Event>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      
      try {
        // Try the optimized query first (requires index)
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('startDate', isGreaterThanOrEqualTo: now)
            .where('isUpcoming', isEqualTo: true)
            .orderBy('startDate')
            .get();

        return querySnapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList();
      } catch (e) {
        if (e.toString().contains('The query requires an index')) {
          // Fallback query while waiting for index
          print('Waiting for Firestore index to be built. Using fallback query.');
          ToastUtils.showToast('Loading events...');
          
          final querySnapshot = await _firestore
              .collection(_collection)
              .orderBy('startDate')
              .get();

          return querySnapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .where((event) => 
                event.startDate.isAfter(now) && 
                event.isUpcoming)
              .toList();
        }
        rethrow;
      }
    } catch (e) {
      print('Error getting upcoming events: $e');
      return [];
    }
  }

  // Search events by title
  Future<List<Event>> searchEvents(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  // Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collection)
          .doc(eventId)
          .get();

      if (!docSnapshot.exists) return null;
      return Event.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }
}
