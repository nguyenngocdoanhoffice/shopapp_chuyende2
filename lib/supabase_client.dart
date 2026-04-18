import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  static const supabaseUrl = 'https://vlgyzqpwqjtbrbhaqavd.supabase.co';
  static const supabaseAnonKey =
      'sb_publishable_YCZh-lDbuyDizKgIdr0XTQ_jkWvycJk';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

SupabaseClient get supabase => Supabase.instance.client;
