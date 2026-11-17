import '/core/enums/language.enum.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/features/users/data/enums/user_role.enum.dart';

final class AppRoutes {
  AppRoutes._();

  // Public / Auth
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const profileDetails = '/profile-details';

  // Core Management
  static const settings = '/settings';
  static const services = '/services';
  static const notifications = '/notifications';
  static const helpSupport = '/help-support';
  static const faqs = '/faqs';
  static const addFaq = '/faqs/add';
  static const editFaq = '/faqs/edit';

  // Users Management
  static const users = '/users';
  static String userDetail({required String id}) {
    return '/users/detail/$id';
  }

  // Customer subroutes
  static const userCustomer = '/users/customer';
  static const userCustomerPending = '/users/customer/pending';
  static const userCustomerVerified = '/users/customer/verified';
  static const userCustomerBlocked = '/users/customer/blocked';

  // Bodyguard subroutes
  static const userGuard = '/users/bodyguard';
  static const userGuardPending = '/users/bodyguard/pending';
  static const userGuardVerified = '/users/bodyguard/verified';
  static const userGuardBlocked = '/users/bodyguard/blocked';

  // Company subroutes
  static const userCompany = '/users/company';
  static const userCompanyPending = '/users/company/pending';
  static const userCompanyVerified = '/users/company/verified';
  static const userCompanyBlocked = '/users/company/blocked';

  // Content / Legal
  static const content = '/content';
  static String contentUrl(ContentType type) => '/content/${type.slug}';

  // Public Legal Documentation Routes
  static const publicLegal = '/public/:contentType/:role/:language';
  static String publicLegalUrl({
    ContentType contentType = ContentType.terms,
    UserRoleType role = UserRoleType.customer,
    LanguageType language = LanguageType.english,
  }) => '/public/${contentType.slug}/${role.slug}/${language.code}';

  /// Returns the full absolute URL including origin
  static String fullPublicLegalUrl({
    ContentType contentType = ContentType.terms,
    UserRoleType role = UserRoleType.customer,
    LanguageType language = LanguageType.english,
  }) {
    final origin = Uri.base.origin;
    final path = publicLegalUrl(
      contentType: contentType,
      role: role,
      language: language,
    );
    return '$origin$path';
  }
}
