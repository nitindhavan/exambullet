import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:percent/models/topic_model.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/percent_loader.dart';
import 'package:percent/widgets/slim_header.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Topic content screen — videos open in the YouTube app/browser (in-app
// WebView embedding was dropped: YouTube's own iframe_api bootstrap has a
// race-condition bug, and even a plain embed gets redirected/blocked for
// videos with embedding disabled by their uploader — both dead ends for
// in-app playback). Articles also open externally.
// Opening the screen auto-marks the topic complete (for signed-in users).
// ══════════════════════════════════════════════════════════════════════════════

class TopicContentScreen extends StatefulWidget {
  const TopicContentScreen({Key? key, required this.topic}) : super(key: key);

  final TopicModel topic;

  @override
  State<TopicContentScreen> createState() => _TopicContentScreenState();
}

class _TopicContentScreenState extends State<TopicContentScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _completed = false;
  List<_VideoItem> _videos = [];
  List<_ArticleItem> _articles = [];

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final snap = await FirebaseDatabase.instance
        .ref('topicContent/${widget.topic.id}')
        .once();
    if (!mounted) return;

    final List<_VideoItem> videos = [];
    final List<_ArticleItem> articles = [];

    if (snap.snapshot.value != null) {
      final raw = Map<dynamic, dynamic>.from(snap.snapshot.value as Map);
      final rawVideos = raw['videos'];
      if (rawVideos is List) {
        for (final v in rawVideos) {
          if (v is Map) videos.add(_VideoItem.fromMap(v));
        }
      } else if (rawVideos is Map) {
        for (final v in rawVideos.values) {
          if (v is Map) videos.add(_VideoItem.fromMap(v));
        }
      }
      final rawArticles = raw['articles'];
      if (rawArticles is List) {
        for (final a in rawArticles) {
          if (a is Map) articles.add(_ArticleItem.fromMap(a));
        }
      } else if (rawArticles is Map) {
        for (final a in rawArticles.values) {
          if (a is Map) articles.add(_ArticleItem.fromMap(a));
        }
      }
    }

    setState(() {
      _videos = videos;
      _articles = articles;
      _loading = false;
    });

    // Auto-mark complete when content is actually available.
    if (videos.isNotEmpty || articles.isNotEmpty) {
      _markComplete();
    }
  }

  Future<void> _markComplete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // Guest: view only, no progress written.
    if (_completed) return;
    try {
      await FirebaseDatabase.instance
          .ref('topicProgress/$uid/${widget.topic.id}')
          .set(true);
      if (mounted) setState(() => _completed = true);
    } catch (_) {
      // Silent — content viewing shouldn't be blocked by a write failure.
    }
  }

  // Tap a video card → open it in the YouTube app (or browser fallback).
  void _playVideo(_VideoItem v) {
    if (v.videoId.isEmpty) return;
    _launch('https://www.youtube.com/watch?v=${v.videoId}');
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasContent = _videos.isNotEmpty || _articles.isNotEmpty;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const PercentLoaderCentered()
                : !hasContent
                    ? _buildComingSoon()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SlimHeader(
      eyebrow: 'Learn',
      title: widget.topic.name,
      onBack: () => Navigator.pop(context, _completed),
      trailing: _completed
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 15),
                  const SizedBox(width: 4),
                  Text('Done',
                      style: GoogleFonts.inter(
                          color: AppTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            )
          : null,
    );
  }

  // ── Main content: tabs (Popular Videos / Articles) ──────────────────────────
  Widget _buildContent() {
    return Column(
      children: [
        Material(
          color: AppTheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            indicatorWeight: 2.5,
            labelStyle:
                GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'YouTube Videos'),
              Tab(text: 'Articles'),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildVideosTab(),
              _buildArticlesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideosTab() {
    if (_videos.isEmpty) {
      return _emptyTabNote('No videos for this topic yet.');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // Clear source label + creator credit.
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded,
                      color: Color(0xffFF0000), size: 18),
                  const SizedBox(width: 6),
                  Text('Top video results from YouTube',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      )),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'These videos are from YouTube and belong to their respective creators. Percent only lists them.',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        ..._videos.map(_buildVideoCard),
      ],
    );
  }

  Widget _buildArticlesTab() {
    if (_articles.isEmpty) {
      return _emptyTabNote('No articles for this topic yet.');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ..._articles.map(_buildArticleTile),
      ],
    );
  }

  Widget _emptyTabNote(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(_VideoItem v) {
    return GestureDetector(
      onTap: () => _playVideo(v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight, width: 1),
          boxShadow: AppTheme.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (v.thumbnail.isNotEmpty)
                    Image.network(
                      v.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.primaryLight,
                        child: const Icon(Icons.ondemand_video_rounded,
                            color: AppTheme.primary, size: 40),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.primaryLight,
                      child: const Icon(Icons.ondemand_video_rounded,
                          color: AppTheme.primary, size: 40),
                    ),
                  Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 34),
                    ),
                  ),
                  if (v.length.isNotEmpty)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(v.length,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35)),
                  if (v.channel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 13, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(v.channel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Reliable way to watch on YouTube (opens the YouTube app).
                  GestureDetector(
                    onTap: () => _launch(
                        'https://www.youtube.com/watch?v=${v.videoId}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xffFF0000).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_circle_fill_rounded,
                              size: 16, color: Color(0xffFF0000)),
                          const SizedBox(width: 6),
                          Text('Watch on YouTube',
                              style: GoogleFonts.inter(
                                  color: const Color(0xffCC0000),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleTile(_ArticleItem a) {
    return GestureDetector(
      onTap: () => _launch(a.url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.link_rounded,
                  color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35)),
                  if (a.source.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(a.source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                            color: AppTheme.textLight, fontSize: 11.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoon() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                  color: AppTheme.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.auto_stories_rounded,
                  size: 38, color: AppTheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 18),
            Text('Content coming soon',
                style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'We are curating the best videos and articles for this topic. Check back shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Lightweight data holders (plain classes, Dart 2.18 safe) ─────────────────

class _VideoItem {
  final String videoId;
  final String title;
  final String channel;
  final String thumbnail;
  final String length;

  _VideoItem({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumbnail,
    required this.length,
  });

  factory _VideoItem.fromMap(Map<dynamic, dynamic> m) => _VideoItem(
        videoId: (m['videoId'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        channel: (m['channel'] ?? '').toString(),
        thumbnail: (m['thumbnail'] ?? '').toString(),
        length: (m['length'] ?? '').toString(),
      );
}

class _ArticleItem {
  final String title;
  final String url;
  final String source;

  _ArticleItem({
    required this.title,
    required this.url,
    required this.source,
  });

  factory _ArticleItem.fromMap(Map<dynamic, dynamic> m) => _ArticleItem(
        title: (m['title'] ?? '').toString(),
        url: (m['url'] ?? '').toString(),
        source: (m['source'] ?? '').toString(),
      );
}
