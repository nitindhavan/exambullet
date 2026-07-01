import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:percent/models/exam.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:percent/utils/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsSection extends StatefulWidget {
  const NewsSection({Key? key, required this.goalExams}) : super(key: key);
  final List<ExamModel> goalExams;

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  late Future<List<Map<String, String>>> _newsFuture;

  static const _fallback = <Map<String, String>>[
    {
      'source': 'Daily Tip',
      'title': 'Practise daily for best results',
      'description': 'Consistent daily practice boosts retention by up to 80%.',
      'date': '',
      'url': ''
    },
    {
      'source': 'Reminder',
      'title': 'Review your weak areas',
      'description': 'Revisit topics you scored low on before your next mock test.',
      'date': '',
      'url': ''
    },
    {
      'source': 'New Content',
      'title': 'Fresh mock tests are live',
      'description': 'New question sets have been added for all exams.',
      'date': '',
      'url': ''
    },
    {
      'source': 'Strategy',
      'title': 'Attempt easy questions first',
      'description': 'Build momentum in mock tests by starting with easier ones.',
      'date': '',
      'url': ''
    },
  ];

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNews();
  }

  @override
  void didUpdateWidget(NewsSection old) {
    super.didUpdateWidget(old);
    final oldIds = old.goalExams.map((e) => e.id).toSet();
    final newIds = widget.goalExams.map((e) => e.id).toSet();
    if (oldIds.length != newIds.length || !oldIds.containsAll(newIds)) {
      _newsFuture = _fetchNews();
      setState(() {});
    }
  }

  Future<List<Map<String, String>>> _fetchNews() async {
    try {
      if (widget.goalExams.isEmpty) return [];

      final results = <Map<String, String>>[];
      final examsToFetch = widget.goalExams.take(4).toList(); 

      final futures = examsToFetch.map((exam) async {
        final query = '${exam.name} exam';
        String urlString = 'https://news.google.com/rss/search?q=${Uri.encodeComponent(query)}&hl=en-IN&gl=IN&ceid=IN:en';
        if (kIsWeb) {
          urlString = 'https://corsproxy.io/?${Uri.encodeComponent(urlString)}';
        }
        try {
          final resp = await http.get(Uri.parse(urlString), headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
          });
          if (resp.statusCode == 200) {
            final localRes = <Map<String, String>>[];
            final itemRx = RegExp(r'<item>([\s\S]*?)<\/item>');
            for (final m in itemRx.allMatches(resp.body).take(6)) {
              final block = m.group(1) ?? '';
              var title = _clean(_tag(block, 'title'));
              final dash = title.lastIndexOf(' - ');
              if (dash > 0) title = title.substring(0, dash);
              final source = _tagAttr(block, 'source');
              final body = _clean(_tag(block, 'description'));
              final url = _parseLink(block);
              final date = _fmtDate(_tag(block, 'pubDate'));
              
              if (title.isNotEmpty) {
                localRes.add({
                  'source': source.isNotEmpty ? source : 'Google News',
                  'title': title,
                  'description': body,
                  'date': date,
                  'url': url,
                });
              }
            }
            return localRes;
          }
        } catch (_) {}
        return <Map<String, String>>[];
      });

      final allResults = await Future.wait(futures);
      for (final r in allResults) {
        results.addAll(r);
      }
      
      results.shuffle(); 
      return results.take(15).toList();
    } catch (_) {
      return [];
    }
  }

  String _parseLink(String block) {
    final el = RegExp(r'<link>([^<]+)<\/link>').firstMatch(block);
    if (el != null) return el.group(1)?.trim() ?? '';
    return _tag(block, 'link');
  }

  String _tag(String xml, String tag) {
    final cdata =
        RegExp('<$tag[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/$tag>');
    final m1 = cdata.firstMatch(xml);
    if (m1 != null) return m1.group(1)?.trim() ?? '';
    return RegExp('<$tag[^>]*>([\\s\\S]*?)<\\/$tag>')
            .firstMatch(xml)
            ?.group(1)
            ?.trim() ??
        '';
  }

  String _tagAttr(String xml, String tag) {
    return RegExp('<$tag[^>]*>([\\s\\S]*?)<\\/$tag>')
            .firstMatch(xml)
            ?.group(1)
            ?.trim() ??
        '';
  }

  String _clean(String html) {
    var s = html
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _fmtDate(String rfc) {
    if (rfc.isEmpty) return '';
    final parts = rfc.split(',');
    if (parts.length > 1) {
      final tokens = parts[1].trim().split(' ');
      if (tokens.length >= 3) return '${tokens[0]} ${tokens[1]} ${tokens[2]}';
    }
    return rfc;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Updates',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder(
                    future: _newsFuture,
                    builder: (context, snap) {
                      final isLive = snap.hasData && snap.data!.isNotEmpty;
                      final isLoading = snap.connectionState == ConnectionState.waiting;
                      if (isLoading) return const SizedBox.shrink();
                      return Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLive
                                  ? AppTheme.success
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isLive ? 'Live · Google News' : 'Curated tips',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
              const Spacer(),
              FutureBuilder(
                future: _newsFuture,
                builder: (context, snap) {
                  final isLoading = snap.connectionState == ConnectionState.waiting;
                  if (isLoading) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _newsFuture = _fetchNews();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: AppTheme.primary, size: 18),
                    ),
                  );
                }
              ),
            ],
          ),
        ),
        FutureBuilder<List<Map<String, String>>>(
          future: _newsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingList();
            }
            final items =
                (snap.data?.isNotEmpty == true) ? snap.data! : _fallback;
            final isLive = snap.data?.isNotEmpty == true;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: items.length,
              itemBuilder: (_, i) => _NewsCard(
                item: items[i],
                isLive: isLive,
              ),
            );
          },
        ),
      ],
    );
  }


}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.isLive});
  final Map<String, String> item;
  final bool isLive;

  void _open(BuildContext context) async {
    final url = item['url'] ?? '';
    if (url.isEmpty) return;
    if (kIsWeb) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ArticleWebView(
          url: url,
          title: item['title'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = isLive ? AppTheme.secondary : AppTheme.primary;
    final tappable = (item['url'] ?? '').isNotEmpty;
    final source = item['source'] ?? '';
    final date = item['date'] ?? '';
    final title = item['title'] ?? '';
    final desc = item['description'] ?? '';

    return GestureDetector(
      onTap: tappable ? () => _open(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12, height: 1.5),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (source.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        source,
                        style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (source.isNotEmpty && date.isNotEmpty)
                    const SizedBox(width: 8),
                  if (date.isNotEmpty)
                    Text(date,
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 11)),
                  if (tappable) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Read',
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 12, color: accent),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleWebView extends StatefulWidget {
  const _ArticleWebView({required this.url, required this.title});
  final String url;
  final String title;

  @override
  State<_ArticleWebView> createState() => _ArticleWebViewState();
}

class _ArticleWebViewState extends State<_ArticleWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  String _currentTitle = '';

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) async {
          if (!mounted) return;
          final pageTitle = await _controller.getTitle() ?? widget.title;
          setState(() {
            _loading = false;
            _currentTitle = pageTitle.isNotEmpty ? pageTitle : widget.title;
          });
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (_loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            LinearProgressIndicator(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              color: AppTheme.primary,
              minHeight: 3,
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}

// ── Shimmer Loading ───────────────────────────────────────────────────────────

class _LoadingList extends StatefulWidget {
  const _LoadingList();

  @override
  State<_LoadingList> createState() => _LoadingListState();
}

class _LoadingListState extends State<_LoadingList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  late final Animation<double> _anim =
      Tween<double>(begin: 0.25, end: 0.65).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: 5,
        itemBuilder: (_, __) => _ShimmerCard(opacity: _anim.value),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final bg =
        Color.lerp(const Color(0xffF1F5F9), const Color(0xffE2E8F0), opacity)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 8),
          Container(
              height: 14,
              width: 200,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 6),
          Container(
              height: 12,
              width: 220,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 14),
          Container(
              height: 22,
              width: 90,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(8))),
        ],
      ),
    );
  }
}
