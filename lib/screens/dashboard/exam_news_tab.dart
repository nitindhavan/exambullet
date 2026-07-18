import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent/models/exam.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:percent/utils/theme.dart';
import 'package:percent/widgets/ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:percent/widgets/percent_loader.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _Article {
  final String title;
  final String description;
  final String source;
  final String date;
  final String url;
  const _Article({
    required this.title,
    required this.description,
    required this.source,
    required this.date,
    required this.url,
  });
}

// ── Tab ───────────────────────────────────────────────────────────────────────

class ExamNewsTab extends StatefulWidget {
  const ExamNewsTab({Key? key, required this.exam}) : super(key: key);
  final ExamModel exam;

  @override
  State<ExamNewsTab> createState() => _ExamNewsTabState();
}

class _ExamNewsTabState extends State<ExamNewsTab> {
  List<_Article> _articles = [];
  bool _loading = true;
  bool _isLive = false;

  static const _fallback = <_Article>[
    _Article(
        title: 'Daily practice boosts retention',
        description:
            'Consistent 30-minute daily sessions improve long-term retention by up to 80%.',
        source: 'Study Tip',
        date: '',
        url: ''),
    _Article(
        title: 'Attempt easy questions first',
        description:
            'Build momentum in mock tests by starting with confident answers before tackling harder questions.',
        source: 'Strategy',
        date: '',
        url: ''),
    _Article(
        title: 'Review your weak areas',
        description:
            'Revisit low-scoring topics before your next mock test. Focus on understanding over memorization.',
        source: 'Reminder',
        date: '',
        url: ''),
    _Article(
        title: 'New mock tests are live',
        description:
            'New question sets reflect the latest exam pattern. Take them now to stay ahead.',
        source: 'Update',
        date: '',
        url: ''),
    _Article(
        title: 'Use the timer wisely',
        description:
            'Practise with the timer on to simulate real exam conditions and improve your time management.',
        source: 'Study Tip',
        date: '',
        url: ''),
  ];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final query = Uri.encodeComponent('${widget.exam.name} exam');
      String urlString = 'https://news.google.com/rss/search?q=$query&hl=en-IN&gl=IN&ceid=IN:en';
      if (kIsWeb) {
        urlString = 'https://corsproxy.io/?${Uri.encodeComponent(urlString)}';
      }
      final uri = Uri.parse(urlString);
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0'
      }).timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final parsed = _parseRss(response.body);
        if (mounted) {
          setState(() {
            _articles = parsed.isNotEmpty ? parsed : _fallback;
            _isLive = parsed.isNotEmpty;
            _loading = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _articles = _fallback;
        _isLive = false;
        _loading = false;
      });
    }
  }

  List<_Article> _parseRss(String xml) {
    final itemRx = RegExp(r'<item>([\s\S]*?)<\/item>');
    return itemRx
        .allMatches(xml)
        .take(15)
        .map((m) {
          final block = m.group(1) ?? '';
          return _Article(
            title: _clean(_tag(block, 'title')),
            description: _clean(_tag(block, 'description')),
            source: _tagAttr(block, 'source'),
            date: _fmtDate(_tag(block, 'pubDate')),
            url: _parseLink(block),
          );
        })
        .where((a) => a.title.isNotEmpty)
        .toList();
  }

  // Google News RSS puts <link> as plain text between tags, not as a normal element.
  // It appears right after <title>...</title> in the item block.
  String _parseLink(String block) {
    // Try <link>url</link>
    final el = RegExp(r'<link>([^<]+)<\/link>').firstMatch(block);
    if (el != null) return el.group(1)?.trim() ?? '';
    // Try self-closing or CDATA variant
    return _tag(block, 'link');
  }

  String _tag(String xml, String tag) {
    final cdata =
        RegExp('<$tag[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]><\\/$tag>');
    final m1 = cdata.firstMatch(xml);
    if (m1 != null) return m1.group(1)?.trim() ?? '';
    final normal = RegExp('<$tag[^>]*>([\\s\\S]*?)<\\/$tag>');
    return normal.firstMatch(xml)?.group(1)?.trim() ?? '';
  }

  // For attributes like <source url="...">Publisher</source>
  String _tagAttr(String xml, String tag) {
    final m = RegExp('<$tag[^>]*>([\\s\\S]*?)<\\/$tag>').firstMatch(xml);
    return m?.group(1)?.trim() ?? '';
  }

  String _clean(String html) {
    // Decode entities FIRST so &lt;a&gt; becomes <a>
    var s = html
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
    // Now strip ALL HTML tags (including those just decoded from entities)
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');
    // Collapse multiple spaces/newlines from stripped tags
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Latest News', style: AppTheme.headingMd),
                  const SizedBox(height: 2),
                  if (!_loading)
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLive
                                ? AppTheme.success
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isLive ? 'Live · Google News' : 'Curated tips',
                          style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                ],
              ),
              const Spacer(),
              if (!_loading)
                GestureDetector(
                  onTap: _fetchNews,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: AppTheme.primary, size: 18),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const PercentLoaderCentered()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _articles.length,
                  itemBuilder: (_, i) => _NewsCard(
                    article: _articles[i],
                    isLive: _isLive,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── News Card ─────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.isLive});
  final _Article article;
  final bool isLive;

  void _open(BuildContext context) async {
    if (article.url.isEmpty) return;
    if (kIsWeb) {
      final uri = Uri.tryParse(article.url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ArticleWebView(
          url: article.url,
          title: article.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = isLive ? AppTheme.secondary : AppTheme.primary;
    final tappable = article.url.isNotEmpty;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.space4),
      onTap: tappable ? () => _open(context) : null,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: AppTheme.body.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            if (article.description.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space3),
              Text(
                article.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySm.copyWith(
                    color: Colors.grey.shade600, height: 1.5),
              ),
            ],
            const SizedBox(height: AppTheme.space4),
            Row(
                children: [
                  if (article.source.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.source,
                        style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (article.source.isNotEmpty && article.date.isNotEmpty)
                    const SizedBox(width: 8),
                  if (article.date.isNotEmpty)
                    Text(article.date,
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
    );
  }
}

// ── In-app WebView ────────────────────────────────────────────────────────────

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
          // Try to grab the real page title after redirect
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
          // ── Custom header ──────────────────────────────
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
                        style: const TextStyle(
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
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // ── Progress bar ───────────────────────────────
          if (_loading)
            const LinearProgressIndicator(
              backgroundColor: AppTheme.primaryLight,
              color: AppTheme.primary,
              minHeight: 3,
            ),
          // ── WebView ────────────────────────────────────
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}

