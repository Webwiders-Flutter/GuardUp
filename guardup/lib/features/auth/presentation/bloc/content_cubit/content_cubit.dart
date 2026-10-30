import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'content_state.dart';

class ContentCubit extends Cubit<ContentState> {
  ContentCubit() : super(ContentInitial());

  Future<void> fetchContent(String id, String langCode) async {
    emit(ContentLoading());
    try {
      final response = await Supabase.instance.client
          .from('contentManagement')
          .select('content')
          .eq('id', id)
          .maybeSingle();

      if (response == null || response['content'] == null) {
        emit(ContentLoaded("<p>No content found.</p>"));
        return;
      }

      final content = response['content'] as Map<String, dynamic>;
      final langKey = langCode == 'ar' ? 'ar' : 'en';
      final html =
          content[langKey] ?? content['en'] ?? "<p>No content available.</p>";

      emit(ContentLoaded(html));
    } catch (e) {
      emit(ContentError("Failed to load content: ${e.toString()}"));
    }
  }
}
