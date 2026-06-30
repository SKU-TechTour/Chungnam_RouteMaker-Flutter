import 'package:flutter/material.dart';
import 'package:flutterprojects/features/home_curation/models/course.dart';

/// 3단 콤보 코스 카드 위젯.
class ComboCard extends StatelessWidget {
  const ComboCard({
    super.key,
    required this.course,
    required this.onSwipe,
  });

  final Course course;
  final ValueChanged<int> onSwipe;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (course.weatherTag != null) ...[
              const SizedBox(height: 8),
              Chip(label: Text(course.weatherTag!)),
            ],
            const SizedBox(height: 16),
            ...course.spots.asMap().entries.map(
                  (entry) => ListTile(
                    leading: CircleAvatar(child: Text('${entry.key + 1}')),
                    title: Text(entry.value),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
