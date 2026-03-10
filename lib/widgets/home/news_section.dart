import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NewsSection extends StatelessWidget {
  NewsSection({Key? key}) : super(key: key);

  static const _colors = [
    Color(0xff4CAF50),
    Color(0xff2196F3),
    Color(0xffFF9800),
    Color(0xff9C27B0),
    Color(0xffF44336),
  ];

  static const _fallback = [
    {'tag': 'Daily Tip', 'title': 'Practise daily for best results', 'body': 'Consistent daily practice boosts retention by up to 80%.'},
    {'tag': 'Reminder', 'title': 'Review your weak areas', 'body': 'Revisit topics you scored low on before your next mock test.'},
    {'tag': 'New Content', 'title': 'Fresh mock tests are live', 'body': 'New question sets have been added for all exams.'},
    {'tag': 'Strategy', 'title': 'Attempt easy questions first', 'body': 'Build momentum in mock tests by starting with easier ones.'},
  ];

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
        StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('news').limitToLast(5).onValue,
          builder: (context, snap) {
            List<Map<String, dynamic>> items = [];
            if (snap.hasData && snap.data!.snapshot.value != null) {
              final raw = snap.data!.snapshot.value as Map;
              items = raw.values
                  .map((v) => Map<String, dynamic>.from(v as Map))
                  .toList()
                  .reversed
                  .toList();
            }
            if (items.isEmpty) items = List.from(_fallback);

            return SizedBox(
              height: 136,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                itemCount: items.length,
                itemBuilder: (_, i) => _NewsCard(item: items[i], color: _colors[i % _colors.length]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.color});
  final Map<String, dynamic> item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item['body'] ?? '',
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 11, height: 1.35),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
