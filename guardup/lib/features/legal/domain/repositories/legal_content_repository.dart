import '../../data/enum/content_type.enum.dart';
import '../../data/model/legal_content.model.dart';

/// Contract defining legal content retrieval.
abstract class LegalContentRepository {
  Future<LegalContentModel> getLegalContent(ContentType type);
}

