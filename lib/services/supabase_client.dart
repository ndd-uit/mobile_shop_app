import 'package:supabase_flutter/supabase_flutter.dart';

/// Shortcut toàn cục để dùng trong toàn bộ services.
SupabaseClient get supabase => Supabase.instance.client;
