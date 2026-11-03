import '../../data/model/contact_us.model.dart';

/// Contract defining contact us submissions.
abstract class ContactUsRepository {
  Future<void> submitContactUs(ContactUsSubmission submission);
}

