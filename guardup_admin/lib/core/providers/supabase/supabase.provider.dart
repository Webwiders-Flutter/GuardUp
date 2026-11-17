import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final goTrueClientProvider = Provider<GoTrueClient>((ref) {
  return Supabase.instance.client.auth;
});

final supabaseStorageProvider = Provider<SupabaseStorageClient>((ref) {
  return Supabase.instance.client.storage;
});

final supabaseFunctionProvider = Provider<FunctionsClient>((ref) {
  return Supabase.instance.client.functions;
});
