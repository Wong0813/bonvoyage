class NewsModel {
  final int id;
  final String title;
  final String content;
  final String? imagePath;
  final String author;
  final String status;
  final DateTime createdAt;

  const NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.author,
    required this.status,
    required this.createdAt,
  });

  bool get isPublished => status == 'published';
}
