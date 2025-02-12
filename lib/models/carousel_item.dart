import 'package:cloud_firestore/cloud_firestore.dart';

enum CarouselLinkType {
  inApp,
  external,
}

class CarouselItem {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;
  final CarouselLinkType? linkType;
  final DateTime createdAt;
  final bool isActive;
  final int order;
  final String? itemId; // ID of the specific sermon or event

  CarouselItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
    this.linkType,
    required this.createdAt,
    required this.isActive,
    required this.order,
    this.itemId,
  });

  factory CarouselItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CarouselItem(
      id: id,
      title: data['title'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'],
      linkUrl: data['linkUrl'],
      linkType: data['linkType'] != null 
          ? CarouselLinkType.values.firstWhere(
              (e) => e.toString() == 'CarouselLinkType.${data['linkType']}',
              orElse: () => CarouselLinkType.external,
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      itemId: data['itemId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'linkType': linkType?.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'order': order,
      'itemId': itemId,
    };
  }
}
