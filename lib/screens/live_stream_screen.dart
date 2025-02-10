import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/live_stream.dart';
import '../services/live_stream_service.dart';
import '../utils/toast_utils.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({Key? key}) : super(key: key);

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final LiveStreamService _liveStreamService = LiveStreamService();
  bool _isLoading = true;
  LiveStream? _currentStream;
  WebViewController? _webViewController;
  bool _webViewCreated = false;
  bool _isFullScreen = false;
  List<LiveStream> _upcomingStreams = [];
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure platform channel is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _initWebView();
      _loadLiveStream();
      _loadUpcomingStreams();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    // Safely dispose WebView
    if (_webViewController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _webViewController?.clearCache();
          _webViewController = null;
        } catch (e) {
          print('Error disposing WebView: $e');
        }
      });
    }
    super.dispose();
  }

  Future<void> _loadUpcomingStreams() async {
    try {
      final streams = await _liveStreamService.getUpcomingStreams();
      if (mounted && !_disposed) {
        setState(() {
          _upcomingStreams = streams;
        });
      }
    } catch (e) {
      print('Error loading upcoming streams: $e');
    }
  }

  void _initWebView() {
    if (_disposed) return;

    try {
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final WebViewController controller =
          WebViewController.fromPlatformCreationParams(params);

      if (controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
      }

      if (!_disposed) {
        setState(() {
          _webViewController = controller;
        });
      }
    } catch (e) {
      print('Error initializing WebView: $e');
    }
  }

  Future<void> _loadLiveStream() async {
    try {
      final stream = await _liveStreamService.getCurrentLiveStream();
      if (!mounted || _disposed) return;
      
      setState(() {
        _currentStream = stream;
        _isLoading = false;
      });
      
      if (stream != null) {
        await _loadUrl(stream.url);
      }
    } catch (e) {
      print('Error loading live stream: $e');
      if (!mounted || _disposed) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUrl(String url) async {
    if (_webViewController == null || _disposed) return;

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || _disposed) return;

      await _webViewController!
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted && !_disposed) {
                setState(() {
                  _isLoading = false;
                  _webViewCreated = true;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              if (mounted && !_disposed) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        );

      if (mounted && !_disposed) {
        await _webViewController!.loadRequest(Uri.parse(url));
      }
    } catch (e) {
      print('Error loading URL in WebView: $e');
      if (mounted && !_disposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _shareStream() {
    if (_currentStream != null) {
      Share.share(
        'Join us for "${_currentStream!.title}" at ${_currentStream!.url}',
        subject: _currentStream!.title,
      );
    }
  }

  Widget _buildHeroSection() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      actions: [
        if (_currentStream != null)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareStream,
            tooltip: 'Share Stream',
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/live_service_header.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: const Text(
          'Live Stream',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildStreamPlayer() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentStream == null) {
      return SliverFillRemaining(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.tv_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No live stream available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_upcomingStreams.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Upcoming Streams',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _upcomingStreams.length,
                  itemBuilder: (context, index) {
                    final stream = _upcomingStreams[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.event),
                        title: Text(stream.title),
                        subtitle: Text(
                          DateFormat('MMM d, y h:mm a').format(stream.startTime),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentStream!.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                      onPressed: () {
                        setState(() {
                          _isFullScreen = !_isFullScreen;
                        });
                      },
                      tooltip: _isFullScreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
                    ),
                  ],
                ),
                if (_currentStream!.startTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Started ${DateFormat('MMM d, y h:mm a').format(_currentStream!.startTime)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.black,
            height: _isFullScreen ? MediaQuery.of(context).size.height : null,
            child: AspectRatio(
              aspectRatio: _isFullScreen ? MediaQuery.of(context).size.aspectRatio : 16 / 9,
              child: _webViewController != null && _webViewCreated
                  ? WebViewWidget(controller: _webViewController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          if (!_isFullScreen) ...[
            const SizedBox(height: 16),
            if (_currentStream!.isLive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: _shareStream,
                          tooltip: 'Share Stream',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_upcomingStreams.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Upcoming Streams',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _upcomingStreams.length,
                itemBuilder: (context, index) {
                  final stream = _upcomingStreams[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(stream.title),
                      subtitle: Text(
                        DateFormat('MMM d, y h:mm a').format(stream.startTime),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadLiveStream();
          await _loadUpcomingStreams();
        },
        child: CustomScrollView(
          physics: _isFullScreen 
              ? const NeverScrollableScrollPhysics() 
              : const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (!_isFullScreen) _buildHeroSection(),
            _buildStreamPlayer(),
          ],
        ),
      ),
    );
  }
}
