import 'supabase_client.dart';

class CategoryService {
  static Future<List<String>> fetchNames() async {
    final data = await supabase
        .from('categories')
        .select('name')
        .eq('is_active', true)
        .order('sort_order', ascending: true)
        .order('name', ascending: true);

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map((row) => row['name'] as String)
        .toList();
  }
}
