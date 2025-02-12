import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/carousel_item.dart';
import '../screens/bible_screen.dart';
import '../screens/sermon_screen.dart';
import '../screens/event_screen.dart';
import '../screens/live_stream_screen.dart';
import '../screens/devotional_screen.dart';

class HomeCarousel extends StatefulWidget {
  final String collectionPath;
  
  const HomeCarousel({
    Key? key,
    required this.collectionPath,
  }) : super(key: key);

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  int _currentIndex = 0;
  final _swiperController = SwiperController();

  Future<void> _handleItemTap(CarouselItem item) async {
    if (item.linkUrl == null) return;

    if (item.linkType == CarouselLinkType.external) {
      final url = Uri.parse(item.linkUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      }
    } else {
      if (context.mounted) {
        // If we have a specific item ID, navigate directly to it
        if (item.itemId != null) {
          if (item.linkUrl!.startsWith('/sermons')) {
            Navigator.pushNamed(context, '/sermons/${item.itemId}');
          } else if (item.linkUrl!.startsWith('/events')) {
            Navigator.pushNamed(context, '/events/${item.itemId}');
          }
        } else {
          // Otherwise, navigate to the main screen
          Navigator.pushNamed(context, item.linkUrl!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(widget.collectionPath)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final items = snapshot.data!.docs.map((doc) {
          return CarouselItem.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              SizedBox(
                height: 200.0,
                child: Swiper(
                  itemCount: items.length,
                  autoplay: true,
                  autoplayDelay: 5000,
                  duration: 300,
                  pagination: const SwiperPagination(
                    margin: EdgeInsets.only(bottom: 5.0),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => _handleItemTap(item),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                item.imageUrl ?? '',
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(0, 1),
                                            blurRadius: 3.0,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16.0,
                                          shadows: const [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 3.0,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }
}
