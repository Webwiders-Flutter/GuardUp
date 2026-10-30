class SupabaseTables {
  // --- Auth & Core User Tables ---
  static const String users = 'users';
  static const String userBlocks = 'user_blocks';
  static const String userReports = 'user_reports';
  static const String commentReports = 'comment_reports';
  static const String videoReports = 'video_reports';

  // --- GuardUp: Bodyguard & Provider Domain ---
  static const String bodyguards = 'bodyguards';
  static const String guardProfiles = 'guard_profiles';
  static const String kycDocuments = 'kyc_documents';
  static const String guardAvailability = 'guard_availability';
  static const String guardCertifications = 'guard_certifications';

  // --- GuardUp: Bookings & Assignments ---
  static const String bookings = 'bookings';
  static const String assignmentTracking = 'assignment_tracking';
  static const String reviews = 'reviews';

  // --- GuardUp: Financials, Stripe & Wallets ---
  static const String wallets = 'wallets';
  static const String walletTransactions = 'wallet_transactions';
  static const String payoutRequests = 'payout_requests';
  static const String platformCommissions = 'platform_commissions';

  // --- GuardUp: Memberships & Subscriptions ---
  static const String membershipPlans = 'membership_plans';
  static const String userMemberships = 'user_memberships';

  // --- GuardUp: Realtime Chat & Family Safety ---
  static const String chatConversations = 'chat_conversations';
  static const String chatMessages = 'chat_messages';
  static const String familyAccess = 'family_access';

  // --- Location Tables ---
  static const String countries = 'countries';
  static const String states = 'states';
  static const String cities = 'cities';

  // --- Support & Help Centre ---
  static const String supportTickets = 'support_tickets';
  static const String ticketReplies = 'ticket_replies';

  // --- Content & App Config ---
  static const String contentManagement = 'content_management';
  static const String notifications = 'notifications';
}
