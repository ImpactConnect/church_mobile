import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/community_post.dart';
import '../../services/community_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/phone_verification_dialog.dart';

class CommunityScreen extends StatefulWidget {
  final CommunityService communityService;

  const CommunityScreen({
    Key? key,
    required this.communityService,
  }) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _thoughtController = TextEditingController();
  bool _isLoading = false;
  bool _isRefreshing = false;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshPosts() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      // Force refresh by waiting briefly
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      ToastUtils.showToast('Failed to refresh posts');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _shareThought() async {
    if (_thoughtController.text.isEmpty) {
      ToastUtils.showToast('Please enter your thought');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.communityService.createPost(_thoughtController.text.trim());
      _thoughtController.clear();
      if (!mounted) return;
      ToastUtils.showToast('Thought shared successfully');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _shareThought,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showPhoneVerificationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PhoneVerificationDialog(
        communityService: widget.communityService,
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh the screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: widget.communityService.isVerifiedMember(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Community'),
              automaticallyImplyLeading: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.phone_android,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Phone Verification Required',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Please verify your phone number to access the community',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showPhoneVerificationDialog,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Verify Phone Number'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Community'),
          ),
          body: RefreshIndicator(
            key: _refreshKey,
            onRefresh: _refreshPosts,
            child: Column(
              children: [
                // Thought input section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _thoughtController,
                          decoration: const InputDecoration(
                            hintText: 'Share your thought...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: null,
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoading ? null : _shareThought,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),

                // Posts list
                Expanded(
                  child: StreamBuilder<List<CommunityPost>>(
                    stream: widget.communityService.getPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData && !_isRefreshing) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final posts = snapshot.data ?? [];

                      if (posts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to share your thoughts!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                // Navigate to post details
                                Navigator.pushNamed(
                                  context,
                                  '/community/post',
                                  arguments: post,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          child: Text(
                                            post.authorName[0].toUpperCase(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.authorName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                timeago.format(post.createdAt),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      post.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.favorite_border),
                                          onPressed: () {
                                            widget.communityService
                                                .toggleLike(post.id);
                                          },
                                        ),
                                        Text('${post.likesCount}'),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.comment_outlined),
                                        const SizedBox(width: 4),
                                        Text('${post.commentsCount}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    super.dispose();
  }
}
