import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_SECRET_KEY']!;

  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }
}
