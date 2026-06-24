import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  static bool get isValid {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.endsWith('.supabase.co') &&
        anonKey.startsWith('eyJ') &&
        anonKey.length > 100;
  }
}
