// lib/services/supabase_singleton.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseManager {
  static final SupabaseManager _instance = SupabaseManager._internal();
  late final SupabaseClient _client;

  // Constructor privado
  SupabaseManager._internal();

  // Getter para acceder a la instancia única
  static SupabaseManager get instance => _instance;

  // Inicializa Supabase una sola vez
  Future<void> init({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _client = Supabase.instance.client;
      print("Supabase inicializado correctamente.");
    } else {
      _client = Supabase.instance.client;
      print("Supabase ya estaba inicializado, usando cliente existente.");
    }
  }

  SupabaseClient get client => _client;
}
