import '/core/constants/api/json_keys.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../enum/contact_us_status.enum.dart';

/// Payload for submitting an inquiry to `public.contact_us`.
class ContactUsRequest {
  const ContactUsRequest({
    this.userId,
    required this.role,
    required this.fullName,
    required this.email,
    required this.message,
    this.status = ContactUsStatus.pending,
  });

  final String? userId;
  final UserRole role;
  final String fullName;
  final String email;
  final String message;
  final ContactUsStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      JsonKeys.userId: ?userId,
      JsonKeys.role: role.apiValue,
      JsonKeys.fullName: fullName.trim(),
      JsonKeys.email: email.trim(),
      JsonKeys.message: message.trim(),
      JsonKeys.status: status.apiValue,
    };
  }
}
