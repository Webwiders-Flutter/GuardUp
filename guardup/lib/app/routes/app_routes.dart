import '/app/screens/not_found_screen.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/body_guard.dart';
import '/features/booking/booking.dart';
import '/features/chat/chat.dart';
import '/features/company/company.dart';
import '/features/customer/customer.dart';
import '/features/guard_detail/guard_detail.dart';
import '/features/legal/legal.dart';
import '/features/notifications/notifications.dart';
import '/features/payments/payments.dart';

final class AppRoutes {
  AppRoutes._();

  // Public / Auth
  static const splash = SplashScreen.route;
  static const selectRole = SelectRoleScreen.route;
  static const login = LoginScreen.route;
  static const signup = SignUpScreen.route;
  static const register = signup;
  static const forgotPassword = ForgotPasswordScreen.route;
  static const emailVerification = EmailVerificationScreen.route;
  static const resetPassword = ResetPasswordScreen.route;
  static const adminApproval = AdminApprovalScreen.route;
  static const accountBlocked = AccountStatusScreen.blockedRoute;
  static const accountDeleted = AccountStatusScreen.deletedRoute;

  // Onboarding / Profile setup
  static const companyProfile = CompanyCompleteProfileScreen.route;
  static const bodyguardProfile = BodyGuardCompleteProfileScreen.route;
  static const bodyguardUploadDocuments = BodyGuardUploadDocumentsScreen.route;
  static const uploadDocuments = UploadDocumentsScreen.route;
  static const registrationFee = RegistrationFeeScreen.route;
  static const paymentSuccess = PaymentSuccessScreen.route;

  // Shell Tabs / Dashboard
  static const home = CustomerHomeScreen.route;
  static const bookings = BookingsScreen.route;
  static const chat = ConversationsScreen.route;
  static const notifications = NotificationsScreen.route;
  static const profile = ProfileScreen.route;

  // Home variants
  static const companyHome = CompanyHomeScreen.route;
  static const bodyguardHome = BodyGuardHomeScreen.route;

  // Profiles & Edit
  static const editProfile = EditProfileScreen.route;
  static const companyEditProfile = CompanyEditProfileScreen.route;
  static const companyInformation = CompanyInformationScreen.route;
  static const companyDetails = CompanyDetailsScreen.route;
  static const bodyguardInformation = BodyGuardProfileScreen.route;
  static const changePassword = ChangePasswordScreen.route;

  // Payments / Wallet / Membership
  static const membershipPlans = MembershipPlansScreen.route;
  static const myWallet = MyWalletScreen.route;
  static const myBankDetails = MyBankDetailsScreen.route;

  // Legal / Support
  static const privacyPolicy = LegalContentScreen.privacyPolicyRoute;
  static const termsAndConditions = LegalContentScreen.termsRoute;
  static const contactUs = ContactUsScreen.route;

  // Customer / Bodyguards
  static const searchBodyguards = SearchBodyguardsScreen.route;
  static const allBodyguards = CompanyBodyguardsScreen.route;
  static const customerBodyGuard = BodyguardsListScreen.route;
  static const customerBodyguardProfile = CustomerBodygaurdProfileScreen.route;
  static const guardDetail = GuardDetailScreen.route;

  // Booking
  static const customerBooking = BookingScreen.route;
  static const customerBookingDetails = CustomerBookingDetailsScreen.route;
  static const bookingConfirmed = CustomerBookingConfirmedScreen.route;

  // Chat
  static const chatDetail = ChatScreen.route;

  // Errors
  static const notFound = NotFoundScreen.route;
}
