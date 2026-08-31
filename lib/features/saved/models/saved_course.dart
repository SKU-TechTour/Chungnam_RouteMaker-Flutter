class SavedCourse {
  const SavedCourse({
    required this.id,
    required this.region,
    required this.title,
    required this.places,
  });

  final String id;
  final String region;
  final String title;
  final List<String> places;

  @override
  bool operator ==(Object other) => other is SavedCourse && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
