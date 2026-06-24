import '../models/models.dart';
import 'api_client.dart';

class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  Future<List<NewsModel>> getPublished() async {
    final res = await ApiClient.instance.get('/api/news', queryParameters: {'publishedOnly': 'true'});
    return _parseNews(res);
  }

  Future<List<NewsModel>> getAll() async {
    final res = await ApiClient.instance.get('/api/news');
    return _parseNews(res);
  }

  Future<int> create({
    required String title,
    required String content,
    String? imagePath,
    required String author,
    String status = 'published',
  }) async {
    final res = await ApiClient.instance.post('/api/news', {
      'title': title,
      'content': content,
      if (imagePath != null) 'imagePath': imagePath,
      'author': author,
      'status': status,
    });
    return res['id'] as int;
  }

  Future<void> update(int id, {String? title, String? content, String? imagePath, String? status}) async {
    await ApiClient.instance.put('/api/news/$id', {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (imagePath != null) 'imagePath': imagePath,
      if (status != null) 'status': status,
    });
  }

  Future<void> delete(int id) async {
    await ApiClient.instance.delete('/api/news/$id');
  }

  List<NewsModel> _parseNews(dynamic res) {
    if (res == null) return [];
    return List<NewsModel>.from((res as List).map((r) {
      final m = Map<String, String?>.from((r as Map).map((key, val) => MapEntry(key.toString(), val?.toString())));
      return NewsModel(
        id: int.parse(m['id'] ?? '0'),
        title: m['title'] ?? '',
        content: m['content'] ?? '',
        imagePath: m['image_path'],
        author: m['author'] ?? 'Admin',
        status: m['status'] ?? 'draft',
        createdAt: parseDate(m['created_at']),
      );
    }));
  }
}
