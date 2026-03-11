import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent/models/exam.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NewsSection extends StatefulWidget {
  const NewsSection({Key? key, required this.goalExams}) : super(key: key);
  final List<ExamModel> goalExams;

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  static const _colors = [
    Color(0xff4CAF50),
    Color(0xff2196F3),
    Color(0xffFF9800),
    Color(0xff9C27B0),
    Color(0xffF44336),
  ];

  static const _fallback = <Map<String, String>>[
    {
      'tag': 'Daily Tip',
      'title': 'Practise daily for best results',
      'body': 'Consistent daily practice boosts retention by up to 80%.',
      'url': ''
    },
    {
      'tag': 'Reminder',
      'title': 'Review your weak areas',
      'body': 'Revisit topics you scored low on before your next mock test.',
      'url': ''
    },
    {
      'tag': 'New Content',
      'title': 'Fresh mock tests are live',
      'body': 'New question sets have been added for all exams.',
      'url': ''
    },
    {
      'tag': 'Strategy',
      'title': 'Attempt easy questions first',
      'body': 'Build momentum in mock tests by starting with easier ones.',
      'url': ''
    },
  ];

  late Future<List<Map<String, String>>> _newsFuture;

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
      _newsFuture = _fetchNews(); // assign outside setState
      setState(() {}); // trigger rebuild only
    }
  }

  Future<List<Map<String, String>>> _fetchNews() async {
    try {
      final names = widget.goalExams.take(3).map((e) => e.name).toList();
      final query =
          names.isEmpty ? 'exam preparation tips India' : names.join(' OR ');

      final uri = Uri.parse(
        'https://news.google.com/rss/search'
        '?q=${Uri.encodeComponent(query)}&hl=en-IN&gl=IN&ceid=IN:en',
      );

      final resp = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0'
      }).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];

      final results = <Map<String, String>>[];
      final itemRx = RegExp(r'<item>([\s\S]*?)<\/item>');

      for (final m in itemRx.allMatches(resp.body).take(5)) {
        final block = m.group(1) ?? '';

        var title = _clean(_tag(block, 'title'));
        // Google News appends " - Source" to each title — strip it
        final dash = title.lastIndexOf(' - ');
        if (dash > 0) title = title.substring(0, dash);

        final source = _tagAttr(block, 'source');
        final body = _clean(_tag(block, 'description'));
        final url = _parseLink(block);

        if (title.isEmpty) continue;
        results.add({
          'tag': source.isNotEmpty ? source : 'Google News',
          'title': title,
          'body': body,
          'url': url,
        });
      }

      return results;
    } catch (_) {
      return [];
    }
  }

  // Google News RSS puts <link> as bare text (not a proper XML element).
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
          child: Text(
            'Latest Updates',
            style: TextStyle(
              color: Color(0xff2D0F5E),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        FutureBuilder<List<Map<String, String>>>(
          future: _newsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final items =
                (snap.data?.isNotEmpty == true) ? snap.data! : _fallback;
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                itemCount: items.length,
                itemBuilder: (_, i) => _NewsCard(
                  item: items[i],
                  color: _colors[i % _colors.length],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.color});
  final Map<String, String> item;
  final Color color;

  void _open(BuildContext context) {
    final url = item['url'] ?? '';
    if (url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ArticleWebView(url: url, title: item['title'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tappable = (item['url'] ?? '').isNotEmpty;
    return GestureDetector(
      onTap: tappable ? () => _open(context) : null,
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item['tag'] ?? '',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item['title'] ?? '',
              style: const TextStyle(
                color: Color(0xff2D0F5E),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                item['body'] ?? '',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 11, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tappable)
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Read',
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 11, color: color),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── In-app WebView (same as exam_news_tab) ────────────────────────────────────

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
      backgroundColor: const Color(0xffF6F2FF),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1E0845), Color(0xff4A1E96)],
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
                            color: Colors.white, strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            LinearProgressIndicator(
              backgroundColor: const Color(0xff3D1975).withOpacity(0.1),
              color: const Color(0xff3D1975),
              minHeight: 3,
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
