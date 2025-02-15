import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/community_post.dart';
import '../../models/community_comment.dart';
import '../../services/community_service.dart';
import '../../utils/toast_utils.dart';

class PostDetailsScreen extends StatefulWidget {
  final CommunityPost post;
  final CommunityService communityService;

  const PostDetailsScreen({
    Key? key,
    required this.post,
    required this.communityService,
  }) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isLiked = false;
  bool _isRefreshing = false;
  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _refreshComments() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkLikeStatus();
    } catch (e) {
      if (!mounted) return;
      ToastUtils.showToast('Failed to refresh comments');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _checkLikeStatus() async {
    try {
      final isLiked = await widget.communityService.isPostLiked(widget.post.id);
      if (mounted) {
        setState(() => _isLiked = isLiked);
      }
    } catch (e) {
      print('Error checking like status: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) {
      ToastUtils.showToast('Please enter a comment');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.communityService.addComment(
        widget.post.id,
        _commentController.text.trim(),
      );
      _commentController.clear();
      if (!mounted) return;
      ToastUtils.showToast('Comment added successfully');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _addComment,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshComments,
        child: Column(
          children: [
            // Post details card
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(widget.post.authorName[0].toUpperCase()),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                timeago.format(widget.post.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(widget.post.content),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : null,
                          ),
                          onPressed: () async {
                            try {
                              await widget.communityService
                                  .toggleLike(widget.post.id);
                              _checkLikeStatus();
                            } catch (e) {
                              ToastUtils.showToast(
                                  'Failed to update like. Please try again.');
                            }
                          },
                        ),
                        Text('${widget.post.likesCount}'),
                        const SizedBox(width: 16),
                        const Icon(Icons.comment_outlined),
                        const SizedBox(width: 4),
                        Text('${widget.post.commentsCount}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Comments section
            Expanded(
              child: StreamBuilder<List<CommunityComment>>(
                stream: widget.communityService.getComments(widget.post.id),
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
                            onPressed: _refreshComments,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData && !_isRefreshing) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
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
                            'No comments yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to comment!',
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
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    child: Text(
                                      comment.authorName[0].toUpperCase(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.authorName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          timeago.format(comment.createdAt),
                                          style:
                                              Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(comment.content),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Comment input
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _addComment,
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
