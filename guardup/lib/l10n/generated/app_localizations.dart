import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'SKY VIORA'**
  String get appTitle;

  /// Title for the home page
  ///
  /// In en, this message translates to:
  /// **'Home Page'**
  String get homePageTitle;

  /// Text showing the number of button presses
  ///
  /// In en, this message translates to:
  /// **'You have pushed the button this many times:'**
  String get counterText;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @featuredTrips.
  ///
  /// In en, this message translates to:
  /// **'Featured Trips'**
  String get featuredTrips;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @ongoingTrips.
  ///
  /// In en, this message translates to:
  /// **'Ongoing Trips'**
  String get ongoingTrips;

  /// No description provided for @upcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Trips'**
  String get upcomingTrips;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your travel journey'**
  String get signInSubtitle;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Login to continue your journey'**
  String get loginToContinue;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @onboarding1Tagline.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE THE WORLD'**
  String get onboarding1Tagline;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Stay together, save together, enjoy more.'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Desc.
  ///
  /// In en, this message translates to:
  /// **'Perfect for budget-friendly shared stays where comfort, affordability, and companionship come together.'**
  String get onboarding1Desc;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Comfort shared is comfort multiplied.'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Desc.
  ///
  /// In en, this message translates to:
  /// **'Emphasizes how shared spaces can still feel cozy, welcoming, and enjoyable.'**
  String get onboarding2Desc;

  /// No description provided for @onboarding3Tagline.
  ///
  /// In en, this message translates to:
  /// **'SAFETY FIRST'**
  String get onboarding3Tagline;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Affordable stays, unforgettable connections.'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Desc.
  ///
  /// In en, this message translates to:
  /// **'Focuses on both cost savings and the human connections that come with shared accommodation.'**
  String get onboarding3Desc;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccount;

  /// No description provided for @joinSkyvioraToday.
  ///
  /// In en, this message translates to:
  /// **'Join SKY VIORA today'**
  String get joinSkyvioraToday;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @haveReviewedAndAgree.
  ///
  /// In en, this message translates to:
  /// **'I have reviewed and agree to the '**
  String get haveReviewedAndAgree;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use '**
  String get termsOfUse;

  /// No description provided for @andText.
  ///
  /// In en, this message translates to:
  /// **'and '**
  String get andText;

  /// No description provided for @startYourCurated.
  ///
  /// In en, this message translates to:
  /// **'Start your curated travel experience.'**
  String get startYourCurated;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get nameHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @mobileNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get mobileNumberHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @whatInspiresYou.
  ///
  /// In en, this message translates to:
  /// **'What inspires you?'**
  String get whatInspiresYou;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get navHome;

  /// No description provided for @navUniversities.
  ///
  /// In en, this message translates to:
  /// **'UNIVERSITIES'**
  String get navUniversities;

  /// No description provided for @navTravel.
  ///
  /// In en, this message translates to:
  /// **'TRAVEL'**
  String get navTravel;

  /// No description provided for @navVideoHub.
  ///
  /// In en, this message translates to:
  /// **'VIDEO HUB'**
  String get navVideoHub;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'SEARCH'**
  String get navSearch;

  /// No description provided for @navMyTrip.
  ///
  /// In en, this message translates to:
  /// **'MY TRIP'**
  String get navMyTrip;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'CHAT'**
  String get navChat;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get navProfile;

  /// No description provided for @chatAction.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatAction;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetDesc.
  ///
  /// In en, this message translates to:
  /// **'Please check your network settings and try again.'**
  String get noInternetDesc;

  /// No description provided for @noInternetButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get noInternetButton;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @myTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTripsTitle;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// No description provided for @changePhone.
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number'**
  String get changePhone;

  /// No description provided for @newEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'New Email Address'**
  String get newEmailLabel;

  /// No description provided for @newPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'New Phone Number'**
  String get newPhoneLabel;

  /// No description provided for @emailChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email update link sent! Please check your new email to confirm.'**
  String get emailChangedSuccess;

  /// No description provided for @phoneChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phone number updated successfully!'**
  String get phoneChangedSuccess;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDeleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notification?'**
  String get confirmDeleteNotification;

  /// No description provided for @confirmClearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all notifications?'**
  String get confirmClearAllNotifications;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreatedSuccess;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @myVideos.
  ///
  /// In en, this message translates to:
  /// **'My Videos'**
  String get myVideos;

  /// No description provided for @versionText.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get versionText;

  /// No description provided for @aboutTrip.
  ///
  /// In en, this message translates to:
  /// **'About this trip'**
  String get aboutTrip;

  /// No description provided for @hostSection.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get hostSection;

  /// No description provided for @joinTripAction.
  ///
  /// In en, this message translates to:
  /// **'Join Trip'**
  String get joinTripAction;

  /// No description provided for @perPerson.
  ///
  /// In en, this message translates to:
  /// **'per person'**
  String get perPerson;

  /// No description provided for @chatInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get chatInbox;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noChatsYet;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get typing;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @noTripsFound.
  ///
  /// In en, this message translates to:
  /// **'No trips found in this category'**
  String get noTripsFound;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search destinations...'**
  String get searchPlaceholder;

  /// No description provided for @exploreDestinations.
  ///
  /// In en, this message translates to:
  /// **'Explore Destinations'**
  String get exploreDestinations;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found for your search'**
  String get noResultsFound;

  /// No description provided for @reviewBooking.
  ///
  /// In en, this message translates to:
  /// **'Review Booking'**
  String get reviewBooking;

  /// No description provided for @priceDetails.
  ///
  /// In en, this message translates to:
  /// **'Price Details'**
  String get priceDetails;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service Fee'**
  String get serviceFee;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @bookingSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Booking Successful!'**
  String get bookingSuccessful;

  /// No description provided for @viewMyTrips.
  ///
  /// In en, this message translates to:
  /// **'View My Trips'**
  String get viewMyTrips;

  /// No description provided for @yourJourneyToSafe.
  ///
  /// In en, this message translates to:
  /// **'Your journey to safe, '**
  String get yourJourneyToSafe;

  /// No description provided for @inspiredTravel.
  ///
  /// In en, this message translates to:
  /// **'inspired travel '**
  String get inspiredTravel;

  /// No description provided for @startsHere.
  ///
  /// In en, this message translates to:
  /// **'starts here.'**
  String get startsHere;

  /// No description provided for @pleaseEnterYourDetailsToContinueYourAdventure.
  ///
  /// In en, this message translates to:
  /// **'Please enter your details to continue your adventure.'**
  String get pleaseEnterYourDetailsToContinueYourAdventure;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @forgotYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotYourPassword;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry, it happens to the best of us.Tell us your email and we\'ll send you a recovery link to get you back to your journey.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @continueToVerification.
  ///
  /// In en, this message translates to:
  /// **'Continue to Verification'**
  String get continueToVerification;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAnAccount;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t have an account? '**
  String get dontHaveAnAccount;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get logIn;

  /// No description provided for @nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get nature;

  /// No description provided for @culture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get culture;

  /// No description provided for @wellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get wellness;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @weHaveSentDigitCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 4-digit code to'**
  String get weHaveSentDigitCodeTo;

  /// No description provided for @toVerifyYourExplorerIdentity.
  ///
  /// In en, this message translates to:
  /// **'to verify your explorer identity.'**
  String get toVerifyYourExplorerIdentity;

  /// No description provided for @didNotReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didNotReceiveCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'RESEND CODE'**
  String get resendCode;

  /// No description provided for @resendCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCodeTitle;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get enterOtp;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @enter4DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 4-digit code sent to your Email address '**
  String get enter4DigitCode;

  /// No description provided for @forVerification.
  ///
  /// In en, this message translates to:
  /// **'for verification.'**
  String get forVerification;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @adminApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'REF SORTED'**
  String get adminApprovalTitle;

  /// No description provided for @adminApprovalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thanks for signing up to RefSorted.'**
  String get adminApprovalSubtitle;

  /// No description provided for @adminApprovalDesc.
  ///
  /// In en, this message translates to:
  /// **'Before your account can be approved we\'ll confirm that you hold the correct referee qualifications, have completed your Garda vetting, and have met all safeguarding requirements as required by the GAA. You\'ll be notified within 24 hours once we\'ve confirmed everything is in order.'**
  String get adminApprovalDesc;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get okButton;

  /// No description provided for @yourJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get yourJourney;

  /// No description provided for @startsHereOnboarding.
  ///
  /// In en, this message translates to:
  /// **'\nStarts Here'**
  String get startsHereOnboarding;

  /// No description provided for @exploreEurope.
  ///
  /// In en, this message translates to:
  /// **'Explore Europe for travel,\nstudy and a better future.'**
  String get exploreEurope;

  /// No description provided for @joinTheCommunity.
  ///
  /// In en, this message translates to:
  /// **'Welcome to SkyViora'**
  String get joinTheCommunity;

  /// No description provided for @createAccountToJoin.
  ///
  /// In en, this message translates to:
  /// **'Create an account to access Visa Services, upload videos, like, comment, save, and more.'**
  String get createAccountToJoin;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Now'**
  String get signUpNow;

  /// No description provided for @touristSights.
  ///
  /// In en, this message translates to:
  /// **'TOURIST SIGHTS'**
  String get touristSights;

  /// No description provided for @universityBooking.
  ///
  /// In en, this message translates to:
  /// **'UNIVERSITY BOOKING'**
  String get universityBooking;

  /// No description provided for @visaServices.
  ///
  /// In en, this message translates to:
  /// **'VISA SERVICES'**
  String get visaServices;

  /// No description provided for @courseBooking.
  ///
  /// In en, this message translates to:
  /// **'COURSE BOOKING'**
  String get courseBooking;

  /// No description provided for @exploreEuropeTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore Europe'**
  String get exploreEuropeTitle;

  /// No description provided for @exploreEuropeDesc.
  ///
  /// In en, this message translates to:
  /// **'Travel, Study and Enjoy \nan Unforgettable Experience'**
  String get exploreEuropeDesc;

  /// No description provided for @bookAConsultant.
  ///
  /// In en, this message translates to:
  /// **'BOOK A CONSULTANT'**
  String get bookAConsultant;

  /// No description provided for @ourKeyServices.
  ///
  /// In en, this message translates to:
  /// **'Our Key Services'**
  String get ourKeyServices;

  /// No description provided for @topCities.
  ///
  /// In en, this message translates to:
  /// **'Top Cities'**
  String get topCities;

  /// No description provided for @aiCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI Travel Companion'**
  String get aiCompanionTitle;

  /// No description provided for @aiCompanionDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart, Personalised. Always here for you. \nAsk anything. plan better, travel smarter.'**
  String get aiCompanionDesc;

  /// No description provided for @askAiAction.
  ///
  /// In en, this message translates to:
  /// **'ASK AI'**
  String get askAiAction;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @searchCourses.
  ///
  /// In en, this message translates to:
  /// **'Search Courses'**
  String get searchCourses;

  /// No description provided for @fullTimeClosed.
  ///
  /// In en, this message translates to:
  /// **'Full time — Closed'**
  String get fullTimeClosed;

  /// No description provided for @requestSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get requestSubmittedTitle;

  /// No description provided for @requestSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request submitted \nsuccessfully'**
  String get requestSubmittedSuccess;

  /// No description provided for @requestReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'We are reviewing your request.\nWe will contact you within 24-48 hours.'**
  String get requestReviewMessage;

  /// No description provided for @viewMyRequests.
  ///
  /// In en, this message translates to:
  /// **'View My Requests'**
  String get viewMyRequests;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @trackYourRequest.
  ///
  /// In en, this message translates to:
  /// **'Track your request'**
  String get trackYourRequest;

  /// No description provided for @requestId.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get requestId;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @requestReceivedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your request has been received.'**
  String get requestReceivedMessage;

  /// No description provided for @inReview.
  ///
  /// In en, this message translates to:
  /// **'In Review'**
  String get inReview;

  /// No description provided for @teamReviewing.
  ///
  /// In en, this message translates to:
  /// **'Our team is reviewing your request.'**
  String get teamReviewing;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @teamContacted.
  ///
  /// In en, this message translates to:
  /// **'Our team has contacted you.'**
  String get teamContacted;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @aboutYou.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get aboutYou;

  /// No description provided for @memberSincePrefix.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSincePrefix;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @soloEXPEDITION.
  ///
  /// In en, this message translates to:
  /// **'SOLO EXPEDITION'**
  String get soloEXPEDITION;

  /// No description provided for @theVenetianCuratedAlgarve.
  ///
  /// In en, this message translates to:
  /// **'The Venetian Curated Algarve'**
  String get theVenetianCuratedAlgarve;

  /// No description provided for @vaniceItaly.
  ///
  /// In en, this message translates to:
  /// **'Vanice, Italy'**
  String get vaniceItaly;

  /// No description provided for @septDate.
  ///
  /// In en, this message translates to:
  /// **'Sept 15 - Sep 20, 2024'**
  String get septDate;

  /// No description provided for @theJourney.
  ///
  /// In en, this message translates to:
  /// **'The Journey'**
  String get theJourney;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @theExperience.
  ///
  /// In en, this message translates to:
  /// **'The Experience'**
  String get theExperience;

  /// No description provided for @exploringTheHiddenGrottos.
  ///
  /// In en, this message translates to:
  /// **'Exploring the hidden grottos and sun- drenched trails of Lagos. This trip is designed for those who find peace in the sound of the Atlantic and the warmth of Mediterranean hospitality. We\'ll be staying in a boutique guest house curated for women, focusing on slow mornings, coastal hikes, and authentic Portuguese dining.'**
  String get exploringTheHiddenGrottos;

  /// No description provided for @contactDetailsArePrivate.
  ///
  /// In en, this message translates to:
  /// **'CONTACT DETAILS ARE PRIVATE'**
  String get contactDetailsArePrivate;

  /// No description provided for @loginToMessage.
  ///
  /// In en, this message translates to:
  /// **'Login to Message'**
  String get loginToMessage;

  /// No description provided for @viewAllTrip.
  ///
  /// In en, this message translates to:
  /// **'VIEW ALL TRIP'**
  String get viewAllTrip;

  /// No description provided for @elenaR.
  ///
  /// In en, this message translates to:
  /// **'Elena R.'**
  String get elenaR;

  /// No description provided for @contactDetailsAreHiddenToProtectOurCommunityMembers.
  ///
  /// In en, this message translates to:
  /// **'Contact details are hidden to protect our community members.'**
  String get contactDetailsAreHiddenToProtectOurCommunityMembers;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faqTitle;

  /// No description provided for @faq1Question.
  ///
  /// In en, this message translates to:
  /// **'How do I book a journey?'**
  String get faq1Question;

  /// No description provided for @faq1Answer.
  ///
  /// In en, this message translates to:
  /// **'You can book a journey by selecting a trip from the search or home feed, clicking \"Join Journey\", and following the checkout process.'**
  String get faq1Answer;

  /// No description provided for @faq2Question.
  ///
  /// In en, this message translates to:
  /// **'Is HerStay safe for solo travelers?'**
  String get faq2Question;

  /// No description provided for @faq2Answer.
  ///
  /// In en, this message translates to:
  /// **'Yes! Safety is our priority. All hosts are verified, and we have a strict community vetting process to ensure a safe environment.'**
  String get faq2Answer;

  /// No description provided for @faq3Question.
  ///
  /// In en, this message translates to:
  /// **'What is the cancellation policy?'**
  String get faq3Question;

  /// No description provided for @faq3Answer.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policies vary by trip. You can find the specific policy under the \"Terms\" section of any trip detail page.'**
  String get faq3Answer;

  /// No description provided for @faq4Question.
  ///
  /// In en, this message translates to:
  /// **'How can I become a host?'**
  String get faq4Question;

  /// No description provided for @faq4Answer.
  ///
  /// In en, this message translates to:
  /// **'To become a host, go to your profile, select \"Host a Trip\", and fill out the verification form. Our team will review it within 24-48 hours.'**
  String get faq4Answer;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @liveChatResponse.
  ///
  /// In en, this message translates to:
  /// **'Average response time: 5 mins'**
  String get liveChatResponse;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @safetyHotline.
  ///
  /// In en, this message translates to:
  /// **'Call Safety Hotline'**
  String get safetyHotline;

  /// No description provided for @safetyHotlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Available 24/7 for urgent issues'**
  String get safetyHotlineDesc;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @serviceType.
  ///
  /// In en, this message translates to:
  /// **'Service Type'**
  String get serviceType;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @consultationsDetail.
  ///
  /// In en, this message translates to:
  /// **'Consultations Detail'**
  String get consultationsDetail;

  /// No description provided for @supportCenter.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get supportCenter;

  /// No description provided for @howCanWeHelpYou.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get howCanWeHelpYou;

  /// No description provided for @startAChat.
  ///
  /// In en, this message translates to:
  /// **'Start a chat'**
  String get startAChat;

  /// No description provided for @chatWithOurSupportTeam.
  ///
  /// In en, this message translates to:
  /// **'Chat with our support team'**
  String get chatWithOurSupportTeam;

  /// No description provided for @createATicket.
  ///
  /// In en, this message translates to:
  /// **'Create a Ticket'**
  String get createATicket;

  /// No description provided for @submitATicketAndWeWillGetBackToYou.
  ///
  /// In en, this message translates to:
  /// **'Submit a ticket and we will get back to you'**
  String get submitATicketAndWeWillGetBackToYou;

  /// No description provided for @yourTickets.
  ///
  /// In en, this message translates to:
  /// **'Your Tickets'**
  String get yourTickets;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose Category'**
  String get chooseCategory;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @typeSubject.
  ///
  /// In en, this message translates to:
  /// **'Type Subject'**
  String get typeSubject;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type Message'**
  String get typeMessage;

  /// No description provided for @chooseAttachment.
  ///
  /// In en, this message translates to:
  /// **'Choose attachment'**
  String get chooseAttachment;

  /// No description provided for @jpgPngPdfMax5mb.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF (Max 5MB)'**
  String get jpgPngPdfMax5mb;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @myChats.
  ///
  /// In en, this message translates to:
  /// **'My Chats'**
  String get myChats;

  /// No description provided for @ticketDetails.
  ///
  /// In en, this message translates to:
  /// **'Ticket Details'**
  String get ticketDetails;

  /// No description provided for @writeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get writeYourMessage;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @myInterests.
  ///
  /// In en, this message translates to:
  /// **'My Interests'**
  String get myInterests;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @myConsultations.
  ///
  /// In en, this message translates to:
  /// **'My Consultations'**
  String get myConsultations;

  /// No description provided for @noRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No requests found'**
  String get noRequestsFound;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTickets;

  /// No description provided for @myChat.
  ///
  /// In en, this message translates to:
  /// **'My Chat'**
  String get myChat;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @uploadedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Documents'**
  String get uploadedDocuments;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchDocument.
  ///
  /// In en, this message translates to:
  /// **'Search Document'**
  String get searchDocument;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @aboutUniversity.
  ///
  /// In en, this message translates to:
  /// **'About University'**
  String get aboutUniversity;

  /// No description provided for @aboutInstitution.
  ///
  /// In en, this message translates to:
  /// **'About Institution'**
  String get aboutInstitution;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'READ MORE'**
  String get readMore;

  /// No description provided for @readLess.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get readLess;

  /// No description provided for @officialSource.
  ///
  /// In en, this message translates to:
  /// **'Official Source'**
  String get officialSource;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @universities.
  ///
  /// In en, this message translates to:
  /// **'Universities'**
  String get universities;

  /// No description provided for @institutions.
  ///
  /// In en, this message translates to:
  /// **'Institutions'**
  String get institutions;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @reportComment.
  ///
  /// In en, this message translates to:
  /// **'Report Comment'**
  String get reportComment;

  /// No description provided for @deleteCommentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get deleteCommentConfirmation;

  /// No description provided for @editComment.
  ///
  /// In en, this message translates to:
  /// **'Edit Comment'**
  String get editComment;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @deleteAccountPasswordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to permanently delete your account.'**
  String get deleteAccountPasswordConfirmation;

  /// No description provided for @selectConsultationType.
  ///
  /// In en, this message translates to:
  /// **'Select Consultation Type'**
  String get selectConsultationType;

  /// No description provided for @chooseTheServiceYouNeedHelpWith.
  ///
  /// In en, this message translates to:
  /// **'Choose the Service you need help with'**
  String get chooseTheServiceYouNeedHelpWith;

  /// No description provided for @visaConsultation.
  ///
  /// In en, this message translates to:
  /// **'Visa Consultation'**
  String get visaConsultation;

  /// No description provided for @visaConsultationDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help with visa process, documents and requirements'**
  String get visaConsultationDesc;

  /// No description provided for @studyAbroadConsultation.
  ///
  /// In en, this message translates to:
  /// **'Study Abroad Consultation'**
  String get studyAbroadConsultation;

  /// No description provided for @studyAbroadConsultationDesc.
  ///
  /// In en, this message translates to:
  /// **'Career guidance and admission support for international studies'**
  String get studyAbroadConsultationDesc;

  /// No description provided for @travelAdvice.
  ///
  /// In en, this message translates to:
  /// **'Travel Advice'**
  String get travelAdvice;

  /// No description provided for @travelAdviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Get personalized travel tips and destination guidance'**
  String get travelAdviceDesc;

  /// No description provided for @consultantFormDefaultDesc.
  ///
  /// In en, this message translates to:
  /// **'I need guidance about student visa process and requirement documents for master’s in Germany.'**
  String get consultantFormDefaultDesc;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @selectPurpose.
  ///
  /// In en, this message translates to:
  /// **'Select Purpose'**
  String get selectPurpose;

  /// No description provided for @typeHere.
  ///
  /// In en, this message translates to:
  /// **'Type Here...'**
  String get typeHere;

  /// No description provided for @optionalFilesIfAny.
  ///
  /// In en, this message translates to:
  /// **'Optional Files (if any)'**
  String get optionalFilesIfAny;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @passportJohn.
  ///
  /// In en, this message translates to:
  /// **'Passport_john.jpg'**
  String get passportJohn;

  /// No description provided for @uploadJpgPngPdf.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF\n(Max 5MB)'**
  String get uploadJpgPngPdf;

  /// No description provided for @typeOfVisa.
  ///
  /// In en, this message translates to:
  /// **'Type of Visa'**
  String get typeOfVisa;

  /// No description provided for @france.
  ///
  /// In en, this message translates to:
  /// **'France'**
  String get france;

  /// No description provided for @changeBtn.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeBtn;

  /// No description provided for @selectVisaType.
  ///
  /// In en, this message translates to:
  /// **'Select Visa Type'**
  String get selectVisaType;

  /// No description provided for @chooseTheTypeOfVisaYouWantToApplyFor.
  ///
  /// In en, this message translates to:
  /// **'Choose the type of visa you want to apply for'**
  String get chooseTheTypeOfVisaYouWantToApplyFor;

  /// No description provided for @tourism.
  ///
  /// In en, this message translates to:
  /// **'Tourism'**
  String get tourism;

  /// No description provided for @study.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get study;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @uploadPaymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Upload Payment Receipt'**
  String get uploadPaymentReceipt;

  /// No description provided for @uploadPaymentReceiptDesc.
  ///
  /// In en, this message translates to:
  /// **'Please upload a screenshot of the payment receipt'**
  String get uploadPaymentReceiptDesc;

  /// No description provided for @screenshotClearDetails.
  ///
  /// In en, this message translates to:
  /// **'Make sure the screenshot is clear and shows the payment details,'**
  String get screenshotClearDetails;

  /// No description provided for @visaTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Visa Type'**
  String get visaTypeTitle;

  /// No description provided for @validFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get validFrom;

  /// No description provided for @validTo.
  ///
  /// In en, this message translates to:
  /// **'Valid To'**
  String get validTo;

  /// No description provided for @requestIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get requestIdTitle;

  /// No description provided for @visaServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Visa Service'**
  String get visaServiceTitle;

  /// No description provided for @whereDoYouWantToGoToday.
  ///
  /// In en, this message translates to:
  /// **'Where do you \nWant to go today?'**
  String get whereDoYouWantToGoToday;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @checkStatus.
  ///
  /// In en, this message translates to:
  /// **'Check status'**
  String get checkStatus;

  /// No description provided for @getAssistance.
  ///
  /// In en, this message translates to:
  /// **'Get assistance'**
  String get getAssistance;

  /// No description provided for @myVisaTitle.
  ///
  /// In en, this message translates to:
  /// **'My Visa'**
  String get myVisaTitle;

  /// No description provided for @downloadVisa.
  ///
  /// In en, this message translates to:
  /// **'Download Visa'**
  String get downloadVisa;

  /// No description provided for @visaServiceWithSpace.
  ///
  /// In en, this message translates to:
  /// **'Visa Service '**
  String get visaServiceWithSpace;

  /// No description provided for @bySkyViora.
  ///
  /// In en, this message translates to:
  /// **'by SKY VIORA'**
  String get bySkyViora;

  /// No description provided for @businessVisa.
  ///
  /// In en, this message translates to:
  /// **'Business Visa'**
  String get businessVisa;

  /// No description provided for @tourismStudyAndBusinessVisa.
  ///
  /// In en, this message translates to:
  /// **'Tourism, Study and Business Visa'**
  String get tourismStudyAndBusinessVisa;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodTitle;

  /// No description provided for @choosePaymentMethodDesc.
  ///
  /// In en, this message translates to:
  /// **'Please transfer the payment using  one of the following methods'**
  String get choosePaymentMethodDesc;

  /// No description provided for @noPaymentMethodsFound.
  ///
  /// In en, this message translates to:
  /// **'No payment methods available right now.'**
  String get noPaymentMethodsFound;

  /// No description provided for @instaPay.
  ///
  /// In en, this message translates to:
  /// **'InstaPay'**
  String get instaPay;

  /// No description provided for @vodafoneCash.
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash'**
  String get vodafoneCash;

  /// No description provided for @bankOfEgyptAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank of Egypt Account'**
  String get bankOfEgyptAccount;

  /// No description provided for @uploadVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Video'**
  String get uploadVideoTitle;

  /// No description provided for @enterTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitleHint;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @preparingUpload.
  ///
  /// In en, this message translates to:
  /// **'Preparing Upload...'**
  String get preparingUpload;

  /// No description provided for @videoTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter video title'**
  String get videoTitleHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @titleTooShort.
  ///
  /// In en, this message translates to:
  /// **'Title must be at least 5 characters'**
  String get titleTooShort;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @videoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Title'**
  String get videoTitle;

  /// No description provided for @enterDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescriptionHint;

  /// No description provided for @videoDescription.
  ///
  /// In en, this message translates to:
  /// **'Video Description'**
  String get videoDescription;

  /// No description provided for @videoDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter video description'**
  String get videoDescriptionHint;

  /// No description provided for @videoFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Files'**
  String get videoFilesTitle;

  /// No description provided for @uploadMp4MovMkv.
  ///
  /// In en, this message translates to:
  /// **'mp4, mov or MKV\n(Max 5MB)'**
  String get uploadMp4MovMkv;

  /// No description provided for @acceptTermsCondition.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get acceptTermsCondition;

  /// No description provided for @courseDetail.
  ///
  /// In en, this message translates to:
  /// **'Course detail'**
  String get courseDetail;

  /// No description provided for @programDetails.
  ///
  /// In en, this message translates to:
  /// **'Program Details'**
  String get programDetails;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @intake.
  ///
  /// In en, this message translates to:
  /// **'Intake'**
  String get intake;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @aboutTheCourse.
  ///
  /// In en, this message translates to:
  /// **'About the Course'**
  String get aboutTheCourse;

  /// No description provided for @aboutTheProgram.
  ///
  /// In en, this message translates to:
  /// **'About the Program'**
  String get aboutTheProgram;

  /// No description provided for @graduate.
  ///
  /// In en, this message translates to:
  /// **'Graduate'**
  String get graduate;

  /// No description provided for @enterAboutYou.
  ///
  /// In en, this message translates to:
  /// **'Enter something about you'**
  String get enterAboutYou;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your profile has been successfully updated.'**
  String get profileUpdatedMessage;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @applicationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Status'**
  String get applicationStatusTitle;

  /// No description provided for @enterDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Detail'**
  String get enterDetailTitle;

  /// No description provided for @enterDetailDesc.
  ///
  /// In en, this message translates to:
  /// **'Please enter your information correctly'**
  String get enterDetailDesc;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @pleaseEnterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterEmailAddress;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @passportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport Number'**
  String get passportNumber;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// No description provided for @appliedOn.
  ///
  /// In en, this message translates to:
  /// **'Applied on'**
  String get appliedOn;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted'**
  String get applicationSubmitted;

  /// No description provided for @documentsVerified.
  ///
  /// In en, this message translates to:
  /// **'Documents Verified'**
  String get documentsVerified;

  /// No description provided for @embassyReview.
  ///
  /// In en, this message translates to:
  /// **'Embassy Review'**
  String get embassyReview;

  /// No description provided for @interviewSchedules.
  ///
  /// In en, this message translates to:
  /// **'Interview Scheduled'**
  String get interviewSchedules;

  /// No description provided for @visaApproved.
  ///
  /// In en, this message translates to:
  /// **'Visa Approved'**
  String get visaApproved;

  /// No description provided for @estimatedDecisionDate.
  ///
  /// In en, this message translates to:
  /// **'Estimated Decision Date'**
  String get estimatedDecisionDate;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @newFilter.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newFilter;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @myRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequestsTitle;

  /// No description provided for @searchRequestNumber.
  ///
  /// In en, this message translates to:
  /// **'Search Request Number'**
  String get searchRequestNumber;

  /// No description provided for @uploadDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocumentsTitle;

  /// No description provided for @passport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// No description provided for @uploadClearCopyOfYourPassport.
  ///
  /// In en, this message translates to:
  /// **'Upload clear copy of your passport'**
  String get uploadClearCopyOfYourPassport;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @submitRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequestTitle;

  /// No description provided for @selectCountryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountryTitle;

  /// No description provided for @noCountryFound.
  ///
  /// In en, this message translates to:
  /// **'No Country Found'**
  String get noCountryFound;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @trackVisaApplication.
  ///
  /// In en, this message translates to:
  /// **'Track Visa Application'**
  String get trackVisaApplication;

  /// No description provided for @purposeOfTravel.
  ///
  /// In en, this message translates to:
  /// **'Purpose of Travel'**
  String get purposeOfTravel;

  /// No description provided for @pleaseSelectPurposeOfTravel.
  ///
  /// In en, this message translates to:
  /// **'Please select purpose of travel'**
  String get pleaseSelectPurposeOfTravel;

  /// No description provided for @anyAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Any additional details...'**
  String get anyAdditionalDetails;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// No description provided for @purposeTourism.
  ///
  /// In en, this message translates to:
  /// **'Tourism'**
  String get purposeTourism;

  /// No description provided for @purposeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get purposeBusiness;

  /// No description provided for @purposeMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get purposeMedical;

  /// No description provided for @purposeStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get purposeStudy;

  /// No description provided for @purposeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get purposeOther;

  /// No description provided for @purposeOfTravelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tourism, Business'**
  String get purposeOfTravelHint;

  /// No description provided for @enterPurpose.
  ///
  /// In en, this message translates to:
  /// **'Enter purpose...'**
  String get enterPurpose;

  /// No description provided for @pleaseEnterPurpose.
  ///
  /// In en, this message translates to:
  /// **'Please enter purpose'**
  String get pleaseEnterPurpose;

  /// No description provided for @passportSizePhotos.
  ///
  /// In en, this message translates to:
  /// **'Passport Size Photos'**
  String get passportSizePhotos;

  /// No description provided for @recentPhotoWithWhiteBackground.
  ///
  /// In en, this message translates to:
  /// **'Recent photo with white background'**
  String get recentPhotoWithWhiteBackground;

  /// No description provided for @flightReservation.
  ///
  /// In en, this message translates to:
  /// **'Flight Reservation'**
  String get flightReservation;

  /// No description provided for @confirmedFlightTickets.
  ///
  /// In en, this message translates to:
  /// **'Confirmed flight tickets'**
  String get confirmedFlightTickets;

  /// No description provided for @hotelBooking.
  ///
  /// In en, this message translates to:
  /// **'Hotel Booking'**
  String get hotelBooking;

  /// No description provided for @hotelReservationOrInvitation.
  ///
  /// In en, this message translates to:
  /// **'Hotel reservation or invitation'**
  String get hotelReservationOrInvitation;

  /// No description provided for @travelInsurance.
  ///
  /// In en, this message translates to:
  /// **'Travel Insurance'**
  String get travelInsurance;

  /// No description provided for @minimumCoverage.
  ///
  /// In en, this message translates to:
  /// **'Minimum coverage \$\$30,000'**
  String get minimumCoverage;

  /// No description provided for @bankStatement.
  ///
  /// In en, this message translates to:
  /// **'Bank Statement'**
  String get bankStatement;

  /// No description provided for @last3MonthsBankStatement.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months bank statement'**
  String get last3MonthsBankStatement;

  /// No description provided for @coverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// No description provided for @explainYourTravelPurpose.
  ///
  /// In en, this message translates to:
  /// **'Explain your travel purpose'**
  String get explainYourTravelPurpose;

  /// No description provided for @documentChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Checklist'**
  String get documentChecklistTitle;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @visaTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Visa Type'**
  String get visaTypeLabel;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!!'**
  String get congratulations;

  /// No description provided for @yourVisaHasBeenApproved.
  ///
  /// In en, this message translates to:
  /// **'Your visa has been approved.'**
  String get yourVisaHasBeenApproved;

  /// No description provided for @visaServiceRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'The visa service request is submitted.'**
  String get visaServiceRequestSubmitted;

  /// No description provided for @applicationNumberMessage.
  ///
  /// In en, this message translates to:
  /// **'Your application number is #{applicationId}.\nA customer service representative will contact you within 24 to 48 hours.'**
  String applicationNumberMessage(String applicationId);

  /// No description provided for @countryGuide.
  ///
  /// In en, this message translates to:
  /// **'Country Guide: {country}'**
  String countryGuide(String country);

  /// No description provided for @bestTimesToVisit.
  ///
  /// In en, this message translates to:
  /// **'Best times to visit'**
  String get bestTimesToVisit;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @cityInformation.
  ///
  /// In en, this message translates to:
  /// **'City Information'**
  String get cityInformation;

  /// No description provided for @searchForTravel.
  ///
  /// In en, this message translates to:
  /// **'Search for travel'**
  String get searchForTravel;

  /// No description provided for @noDestinationsFound.
  ///
  /// In en, this message translates to:
  /// **'No destinations found.'**
  String get noDestinationsFound;

  /// No description provided for @searchForUniversities.
  ///
  /// In en, this message translates to:
  /// **'Search for universities'**
  String get searchForUniversities;

  /// No description provided for @noUniversitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No universities found'**
  String get noUniversitiesFound;

  /// No description provided for @noProgramsFound.
  ///
  /// In en, this message translates to:
  /// **'No programs found'**
  String get noProgramsFound;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @programs.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programs;

  /// No description provided for @universityDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The 36 colleges and three societies are a core element of the University, to which they are related via a federal system.'**
  String get universityDescriptionPlaceholder;

  /// No description provided for @searchForPrograms.
  ///
  /// In en, this message translates to:
  /// **'Search for Programs'**
  String get searchForPrograms;

  /// No description provided for @associatedWith.
  ///
  /// In en, this message translates to:
  /// **'Associated with:'**
  String get associatedWith;

  /// No description provided for @institutionDescriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Each college is independent and self-governing, having a charter approved by the Privy Council, under which it is governed by a'**
  String get institutionDescriptionPlaceholder;

  /// No description provided for @touristAttractions.
  ///
  /// In en, this message translates to:
  /// **'TOURIST ATTRACTIONS'**
  String get touristAttractions;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get forYou;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'ASK AI'**
  String get askAi;

  /// No description provided for @helloImSkyvioraAssistant.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m Skyviora Assistant'**
  String get helloImSkyvioraAssistant;

  /// No description provided for @askMeAnythingAboutStudying.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about studying, traveling, or visas in Europe.'**
  String get askMeAnythingAboutStudying;

  /// No description provided for @youCanAskMeAbout.
  ///
  /// In en, this message translates to:
  /// **'You can ask me about:'**
  String get youCanAskMeAbout;

  /// No description provided for @writeYourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Write your Question'**
  String get writeYourQuestion;

  /// No description provided for @universitiesAndPrograms.
  ///
  /// In en, this message translates to:
  /// **'Universities and programs'**
  String get universitiesAndPrograms;

  /// No description provided for @visaRequirements.
  ///
  /// In en, this message translates to:
  /// **'Visa requirements'**
  String get visaRequirements;

  /// No description provided for @travelDestinations.
  ///
  /// In en, this message translates to:
  /// **'Travel destinations'**
  String get travelDestinations;

  /// No description provided for @costsAndScholarships.
  ///
  /// In en, this message translates to:
  /// **'Costs and scholarships'**
  String get costsAndScholarships;

  /// No description provided for @livingInEurope.
  ///
  /// In en, this message translates to:
  /// **'Living in Europe'**
  String get livingInEurope;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @eachCollegeIsIndependent.
  ///
  /// In en, this message translates to:
  /// **'Each college is independent and self-governing, having a charter approved by the Privy Council, under which it is governed by a'**
  String get eachCollegeIsIndependent;

  /// No description provided for @searchForInstitutions.
  ///
  /// In en, this message translates to:
  /// **'Search for Institutions'**
  String get searchForInstitutions;

  /// No description provided for @noInstitutionsFound.
  ///
  /// In en, this message translates to:
  /// **'No institutions found'**
  String get noInstitutionsFound;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @programType.
  ///
  /// In en, this message translates to:
  /// **'Program type'**
  String get programType;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @pleaseChooseCountry.
  ///
  /// In en, this message translates to:
  /// **'Please choose country'**
  String get pleaseChooseCountry;

  /// No description provided for @pleaseChooseState.
  ///
  /// In en, this message translates to:
  /// **'Please choose state'**
  String get pleaseChooseState;

  /// No description provided for @pleaseChooseCity.
  ///
  /// In en, this message translates to:
  /// **'Please choose City'**
  String get pleaseChooseCity;

  /// No description provided for @pleaseChooseProgram.
  ///
  /// In en, this message translates to:
  /// **'Please choose Program'**
  String get pleaseChooseProgram;

  /// No description provided for @oSRanking.
  ///
  /// In en, this message translates to:
  /// **'World Ranking'**
  String get oSRanking;

  /// No description provided for @founded.
  ///
  /// In en, this message translates to:
  /// **'Founded'**
  String get founded;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @tuitionFees.
  ///
  /// In en, this message translates to:
  /// **'Tuition Fees'**
  String get tuitionFees;

  /// No description provided for @uploadYourVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Your Video'**
  String get uploadYourVideo;

  /// No description provided for @uploadVideoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your video and get expert guidance faster.'**
  String get uploadVideoSubtitle;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @tourist.
  ///
  /// In en, this message translates to:
  /// **'Tourist'**
  String get tourist;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @tapToUploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Tap to Upload Video'**
  String get tapToUploadVideo;

  /// No description provided for @supportedVideoFormats.
  ///
  /// In en, this message translates to:
  /// **'MP4, MOV, MKV\nMaximum file size 5MB'**
  String get supportedVideoFormats;

  /// No description provided for @videoUploadTip.
  ///
  /// In en, this message translates to:
  /// **'For better review quality, upload a clear video with good lighting.'**
  String get videoUploadTip;

  /// No description provided for @recoveryEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Recovery email sent'**
  String get recoveryEmailSent;

  /// No description provided for @createNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPasswordTitle;

  /// No description provided for @visaAssistance.
  ///
  /// In en, this message translates to:
  /// **'Visa Assistance'**
  String get visaAssistance;

  /// No description provided for @technicalIssue.
  ///
  /// In en, this message translates to:
  /// **'Technical Issue'**
  String get technicalIssue;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @failedToLoadBanners.
  ///
  /// In en, this message translates to:
  /// **'Failed to load banners: {message}'**
  String failedToLoadBanners(String message);

  /// No description provided for @examplePassport.
  ///
  /// In en, this message translates to:
  /// **'A12345678'**
  String get examplePassport;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1h'**
  String get oneHour;

  /// No description provided for @dummyCourseTitle.
  ///
  /// In en, this message translates to:
  /// **'DPhil in Anthropology'**
  String get dummyCourseTitle;

  /// No description provided for @dummyDate.
  ///
  /// In en, this message translates to:
  /// **'12 May 2026'**
  String get dummyDate;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @seeLess.
  ///
  /// In en, this message translates to:
  /// **'See Less'**
  String get seeLess;

  /// No description provided for @stateInformation.
  ///
  /// In en, this message translates to:
  /// **'State Information'**
  String get stateInformation;

  /// No description provided for @noCoursesFound.
  ///
  /// In en, this message translates to:
  /// **'No courses found'**
  String get noCoursesFound;

  /// No description provided for @noCitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No Cities Found'**
  String get noCitiesFound;

  /// No description provided for @noStatesFound.
  ///
  /// In en, this message translates to:
  /// **'No States Found'**
  String get noStatesFound;

  /// No description provided for @emailAddressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Email address not found.'**
  String get emailAddressNotFound;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @newPasswordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from old password'**
  String get newPasswordMustBeDifferent;

  /// No description provided for @programIdIsMissing.
  ///
  /// In en, this message translates to:
  /// **'Program ID is missing'**
  String get programIdIsMissing;

  /// No description provided for @verificationEmailSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent successfully!'**
  String get verificationEmailSentSuccessfully;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @weHaveSentVerificationLink.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to {email}. Please verify your email to unlock all features of the app.'**
  String weHaveSentVerificationLink(String email);

  /// No description provided for @yourEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'your email address'**
  String get yourEmailAddress;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @resendEmailIn.
  ///
  /// In en, this message translates to:
  /// **'Resend Email in {seconds} s'**
  String resendEmailIn(int seconds);

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @pleaseEnterStrongNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a strong new password.'**
  String get pleaseEnterStrongNewPassword;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification Failed'**
  String get verificationFailed;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email Verified!'**
  String get emailVerified;

  /// No description provided for @theLinkIsInvalidOrExpired.
  ///
  /// In en, this message translates to:
  /// **'The link is invalid or has expired.'**
  String get theLinkIsInvalidOrExpired;

  /// No description provided for @yourEmailHasBeenSuccessfullyVerified.
  ///
  /// In en, this message translates to:
  /// **'Your email has been successfully verified. You will be redirected shortly.'**
  String get yourEmailHasBeenSuccessfullyVerified;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @pleaseSelectCountryAndPurpose.
  ///
  /// In en, this message translates to:
  /// **'Please select country and purpose'**
  String get pleaseSelectCountryAndPurpose;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city...'**
  String get searchCity;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @searchState.
  ///
  /// In en, this message translates to:
  /// **'Search state...'**
  String get searchState;

  /// No description provided for @selectState.
  ///
  /// In en, this message translates to:
  /// **'Select State'**
  String get selectState;

  /// No description provided for @uploadDocumentInfo.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG or PDF\n(Max 5MB)'**
  String get uploadDocumentInfo;

  /// No description provided for @documentVerified.
  ///
  /// In en, this message translates to:
  /// **'Document Verified'**
  String get documentVerified;

  /// No description provided for @interviewScheduled.
  ///
  /// In en, this message translates to:
  /// **'Interview Scheduled'**
  String get interviewScheduled;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @serviceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Service Completed'**
  String get serviceCompleted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces are not allowed'**
  String get validationNoSpaces;

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordMinLength;

  /// No description provided for @validationConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get validationConfirmPasswordRequired;

  /// No description provided for @validationPasswordsNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsNotMatch;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get validationNameRequired;

  /// No description provided for @validationNameCapital.
  ///
  /// In en, this message translates to:
  /// **'First letter must be capital'**
  String get validationNameCapital;

  /// No description provided for @validationNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid name'**
  String get validationNameInvalid;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get validationPhoneRequired;

  /// No description provided for @validationPhoneDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only digits are allowed'**
  String get validationPhoneDigitsOnly;

  /// No description provided for @validationPhoneLength.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 10 digits'**
  String get validationPhoneLength;

  /// No description provided for @validationDobRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get validationDobRequired;

  /// No description provided for @validationPassportRequired.
  ///
  /// In en, this message translates to:
  /// **'Passport number is required'**
  String get validationPassportRequired;

  /// No description provided for @validationPassportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter valid passport number'**
  String get validationPassportInvalid;

  /// No description provided for @validationPassportTooShort.
  ///
  /// In en, this message translates to:
  /// **'Passport number is too short'**
  String get validationPassportTooShort;

  /// No description provided for @validationPassportTooLong.
  ///
  /// In en, this message translates to:
  /// **'Passport number is too long'**
  String get validationPassportTooLong;

  /// No description provided for @requestIdWithValue.
  ///
  /// In en, this message translates to:
  /// **'Request ID: #{id}'**
  String requestIdWithValue(String id);

  /// No description provided for @submittedOnWithDate.
  ///
  /// In en, this message translates to:
  /// **'Submitted on: {date}'**
  String submittedOnWithDate(String date);

  /// No description provided for @viewDetail.
  ///
  /// In en, this message translates to:
  /// **'View Detail'**
  String get viewDetail;

  /// No description provided for @noVisaTypesFound.
  ///
  /// In en, this message translates to:
  /// **'No Visa Types Found'**
  String get noVisaTypesFound;

  /// No description provided for @pendingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Pending confirmation'**
  String get pendingConfirmation;

  /// No description provided for @targetCountry.
  ///
  /// In en, this message translates to:
  /// **'Target Countries'**
  String get targetCountry;

  /// No description provided for @selectTargetCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Target Countries'**
  String get selectTargetCountry;

  /// No description provided for @videoLanguage.
  ///
  /// In en, this message translates to:
  /// **'Video Language'**
  String get videoLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @postVideoBtn.
  ///
  /// In en, this message translates to:
  /// **'Post Video'**
  String get postVideoBtn;

  /// No description provided for @uploadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading Video...'**
  String get uploadingVideo;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video uploaded successfully!'**
  String get uploadSuccess;

  /// No description provided for @editVideo.
  ///
  /// In en, this message translates to:
  /// **'Edit Video'**
  String get editVideo;

  /// No description provided for @videoUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Video updated successfully!'**
  String get videoUpdatedSuccessfully;

  /// No description provided for @allCountries.
  ///
  /// In en, this message translates to:
  /// **'All Countries'**
  String get allCountries;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @fillRequiredFieldsAndSelectVideo.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields and select a video.'**
  String get fillRequiredFieldsAndSelectVideo;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @noNotificationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notifications available'**
  String get noNotificationsAvailable;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to comment!'**
  String get noCommentsYet;

  /// No description provided for @loginToAddComment.
  ///
  /// In en, this message translates to:
  /// **'Log in to add a comment'**
  String get loginToAddComment;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// No description provided for @applicantInformation.
  ///
  /// In en, this message translates to:
  /// **'Applicant Information'**
  String get applicantInformation;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @noDocumentsUploaded.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded.'**
  String get noDocumentsUploaded;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @paymentReceipts.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipts'**
  String get paymentReceipts;

  /// No description provided for @documentTitle.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentTitle;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @viewFile.
  ///
  /// In en, this message translates to:
  /// **'View File'**
  String get viewFile;

  /// No description provided for @visaApplicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Visa Application'**
  String get visaApplicationTitle;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorServer;

  /// No description provided for @errorUserNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated. Please log in.'**
  String get errorUserNotAuthenticated;

  /// No description provided for @errorFailedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data. Please try again.'**
  String get errorFailedToLoadData;

  /// No description provided for @errorFailedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update. Please try again.'**
  String get errorFailedToUpdate;

  /// No description provided for @errorFailedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete. Please try again.'**
  String get errorFailedToDelete;

  /// No description provided for @errorFailedToUpload.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload. Please try again.'**
  String get errorFailedToUpload;

  /// No description provided for @errorConnectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please check your internet.'**
  String get errorConnectionTimedOut;

  /// No description provided for @errorResourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found.'**
  String get errorResourceNotFound;

  /// No description provided for @errorInvalidFileType.
  ///
  /// In en, this message translates to:
  /// **'Invalid file type.'**
  String get errorInvalidFileType;

  /// No description provided for @errorRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled.'**
  String get errorRequestCancelled;

  /// No description provided for @errorAlreadyReported.
  ///
  /// In en, this message translates to:
  /// **'You have already reported this video.'**
  String get errorAlreadyReported;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {type}'**
  String reportTitle(String type);

  /// No description provided for @reportTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get reportTypeVideo;

  /// No description provided for @reportTypeComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get reportTypeComment;

  /// No description provided for @reportTypeUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get reportTypeUser;

  /// No description provided for @reportQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this {type}?'**
  String reportQuestion(String type);

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonNudity.
  ///
  /// In en, this message translates to:
  /// **'Nudity or sexual activity'**
  String get reportReasonNudity;

  /// No description provided for @reportReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or graphic content'**
  String get reportReasonViolence;

  /// No description provided for @reportReasonHateSpeech.
  ///
  /// In en, this message translates to:
  /// **'Hate speech or symbols'**
  String get reportReasonHateSpeech;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonMisinformation.
  ///
  /// In en, this message translates to:
  /// **'Misinformation'**
  String get reportReasonMisinformation;

  /// No description provided for @reportReasonCopyright.
  ///
  /// In en, this message translates to:
  /// **'Intellectual property infringement'**
  String get reportReasonCopyright;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide more details...'**
  String get reportDetailsHint;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get reportSubmit;

  /// No description provided for @reportSuccess.
  ///
  /// In en, this message translates to:
  /// **'{type} reported successfully. Thank you for your feedback.'**
  String reportSuccess(String type);

  /// No description provided for @reportOtherDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide more details for \"Other\" reason.'**
  String get reportOtherDetailsRequired;

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeAgoJustNow;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize Your Experience'**
  String get preferencesTitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your interests and preferred destinations to get personalized recommendations.'**
  String get preferencesSubtitle;

  /// No description provided for @preferencesInterestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Interests'**
  String get preferencesInterestsLabel;

  /// No description provided for @preferencesDestinationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Destinations'**
  String get preferencesDestinationsLabel;

  /// No description provided for @addDestinations.
  ///
  /// In en, this message translates to:
  /// **'Add Destinations'**
  String get addDestinations;

  /// No description provided for @editDestinations.
  ///
  /// In en, this message translates to:
  /// **'Edit Destinations'**
  String get editDestinations;

  /// No description provided for @preferencesInterestsHint.
  ///
  /// In en, this message translates to:
  /// **'What are you passionate about?'**
  String get preferencesInterestsHint;

  /// No description provided for @preferencesDestinationsHint.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to go?'**
  String get preferencesDestinationsHint;

  /// No description provided for @preferencesSearchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get preferencesSearchCountry;

  /// No description provided for @preferencesSave.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get preferencesSave;

  /// No description provided for @preferencesSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get preferencesSkip;

  /// No description provided for @preferencesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Preferences updated successfully!'**
  String get preferencesUpdated;

  /// No description provided for @preferencesError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save preferences. Please try again.'**
  String get preferencesError;

  /// No description provided for @interestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interestsLabel;

  /// No description provided for @preferredDestinationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Destinations'**
  String get preferredDestinationsLabel;

  /// No description provided for @editPreferences.
  ///
  /// In en, this message translates to:
  /// **'Edit Preferences'**
  String get editPreferences;

  /// No description provided for @loadingInterests.
  ///
  /// In en, this message translates to:
  /// **'Loading interests...'**
  String get loadingInterests;

  /// No description provided for @noInterestsFound.
  ///
  /// In en, this message translates to:
  /// **'No interests found.'**
  String get noInterestsFound;

  /// No description provided for @reportVideo.
  ///
  /// In en, this message translates to:
  /// **'Report Video'**
  String get reportVideo;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report User'**
  String get reportUser;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @blockUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user? You will no longer see their content.'**
  String get blockUserConfirmation;

  /// No description provided for @unblockUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock this user? You will be able to see their content again.'**
  String get unblockUserConfirmation;

  /// No description provided for @blockSuccess.
  ///
  /// In en, this message translates to:
  /// **'User blocked successfully.'**
  String get blockSuccess;

  /// No description provided for @unblockSuccess.
  ///
  /// In en, this message translates to:
  /// **'User unblocked successfully.'**
  String get unblockSuccess;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @notInterested.
  ///
  /// In en, this message translates to:
  /// **'Not Interested in This Type of Content'**
  String get notInterested;

  /// No description provided for @interviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Interview Details'**
  String get interviewDetails;

  /// No description provided for @interviewDate.
  ///
  /// In en, this message translates to:
  /// **'Interview Date'**
  String get interviewDate;

  /// No description provided for @interviewTime.
  ///
  /// In en, this message translates to:
  /// **'Interview Time'**
  String get interviewTime;

  /// No description provided for @interviewLocation.
  ///
  /// In en, this message translates to:
  /// **'Interview Location'**
  String get interviewLocation;

  /// No description provided for @meetingLink.
  ///
  /// In en, this message translates to:
  /// **'Meeting Link'**
  String get meetingLink;

  /// No description provided for @interviewNotes.
  ///
  /// In en, this message translates to:
  /// **'Interview Notes'**
  String get interviewNotes;

  /// No description provided for @joinMeeting.
  ///
  /// In en, this message translates to:
  /// **'Join Meeting'**
  String get joinMeeting;

  /// No description provided for @adminResponse.
  ///
  /// In en, this message translates to:
  /// **'Admin Response'**
  String get adminResponse;

  /// No description provided for @searchVideos.
  ///
  /// In en, this message translates to:
  /// **'Search videos...'**
  String get searchVideos;

  /// No description provided for @startSearching.
  ///
  /// In en, this message translates to:
  /// **'Start searching for videos'**
  String get startSearching;

  /// No description provided for @noVideosFound.
  ///
  /// In en, this message translates to:
  /// **'No videos found'**
  String get noVideosFound;

  /// No description provided for @videoCover.
  ///
  /// In en, this message translates to:
  /// **'Video Cover'**
  String get videoCover;

  /// No description provided for @chooseCustom.
  ///
  /// In en, this message translates to:
  /// **'Choose custom'**
  String get chooseCustom;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @bitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get bitrate;

  /// No description provided for @uploadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploadingProgress;

  /// No description provided for @verticalOnlyRequirement.
  ///
  /// In en, this message translates to:
  /// **'9:16 Vertical and 16:9 Horizontal'**
  String get verticalOnlyRequirement;

  /// No description provided for @portraitRequirement.
  ///
  /// In en, this message translates to:
  /// **'Portrait & Landscape'**
  String get portraitRequirement;

  /// No description provided for @mp4MovRequirement.
  ///
  /// In en, this message translates to:
  /// **'MP4 · MOV'**
  String get mp4MovRequirement;

  /// No description provided for @maxSizeRequirement.
  ///
  /// In en, this message translates to:
  /// **'Max 4 GB'**
  String get maxSizeRequirement;

  /// No description provided for @maxDurationRequirement.
  ///
  /// In en, this message translates to:
  /// **'Max 10 min'**
  String get maxDurationRequirement;

  /// No description provided for @unsupportedFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsupported Format'**
  String get unsupportedFormatTitle;

  /// No description provided for @unsupportedFormatDesc.
  ///
  /// In en, this message translates to:
  /// **'Only MP4 and MOV videos are supported.\n\nPlease record or export your video in one of these formats and try again.'**
  String get unsupportedFormatDesc;

  /// No description provided for @unsupportedFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Supported: .mp4 · .mov'**
  String get unsupportedFormatHint;

  /// No description provided for @unsupportedFormatToast.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Unsupported format — use MP4 or MOV.'**
  String get unsupportedFormatToast;

  /// No description provided for @fileTooLargeTitle.
  ///
  /// In en, this message translates to:
  /// **'File Too Large'**
  String get fileTooLargeTitle;

  /// No description provided for @fileTooLargeDesc.
  ///
  /// In en, this message translates to:
  /// **'The video file size exceeds the maximum allowed limit.\n\nYour video is {fileMB} MB. The maximum allowed limit is 4 GB.'**
  String fileTooLargeDesc(String fileMB);

  /// No description provided for @fileTooLargeHint.
  ///
  /// In en, this message translates to:
  /// **'Maximum size: 4 GB'**
  String get fileTooLargeHint;

  /// No description provided for @fileTooLargeToast.
  ///
  /// In en, this message translates to:
  /// **'⚠️ The video file size exceeds the maximum allowed limit (4 GB).'**
  String get fileTooLargeToast;

  /// No description provided for @videoTooLongTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Too Long'**
  String get videoTooLongTitle;

  /// No description provided for @videoTooLongDesc.
  ///
  /// In en, this message translates to:
  /// **'Your video is {mins}m {secs}s, which exceeds the 10-minute limit.\n\nPlease trim your video and try again.'**
  String videoTooLongDesc(int mins, int secs);

  /// No description provided for @videoTooLongHint.
  ///
  /// In en, this message translates to:
  /// **'Maximum duration: 10 minutes'**
  String get videoTooLongHint;

  /// No description provided for @videoTooLongToast.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Video too long — max 10 minutes allowed.'**
  String get videoTooLongToast;

  /// No description provided for @cannotReadVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot Read Video'**
  String get cannotReadVideoTitle;

  /// No description provided for @cannotReadVideoDesc.
  ///
  /// In en, this message translates to:
  /// **'We could not read this video\'s dimensions.\n\nPlease try a different video file.'**
  String get cannotReadVideoDesc;

  /// No description provided for @cannotReadVideoHint.
  ///
  /// In en, this message translates to:
  /// **'Only MP4 / MOV in portrait format'**
  String get cannotReadVideoHint;

  /// No description provided for @cannotReadVideoToast.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Cannot read video dimensions. Try another file.'**
  String get cannotReadVideoToast;

  /// No description provided for @videoNotLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Video'**
  String get videoNotLocalTitle;

  /// No description provided for @videoNotLocalDesc.
  ///
  /// In en, this message translates to:
  /// **'The video could not be loaded. This can happen if:\n\n• The video is stored in the cloud (Google Photos) and not downloaded yet.\n• Your device storage is almost full and there isn\'t enough space to process the video.'**
  String get videoNotLocalDesc;

  /// No description provided for @videoNotLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Free up storage or download the video locally, then try again.'**
  String get videoNotLocalHint;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @unselectAll.
  ///
  /// In en, this message translates to:
  /// **'Unselect All'**
  String get unselectAll;

  /// No description provided for @verticalVideoRequired.
  ///
  /// In en, this message translates to:
  /// **'Vertical Video Required'**
  String get verticalVideoRequired;

  /// No description provided for @videoOrientationDesc.
  ///
  /// In en, this message translates to:
  /// **'Your video is {width}×{height} (landscape/square).\nOnly vertical videos in 9:16 portrait orientation are accepted.'**
  String videoOrientationDesc(int width, int height);

  /// No description provided for @requiredPortrait916.
  ///
  /// In en, this message translates to:
  /// **'Required: 9:16 portrait (e.g. 1080×1920)'**
  String get requiredPortrait916;

  /// No description provided for @chooseAnotherVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose Another Video'**
  String get chooseAnotherVideo;

  /// No description provided for @invalidVideoFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid Video File'**
  String get invalidVideoFileTitle;

  /// No description provided for @invalidVideoFileBody.
  ///
  /// In en, this message translates to:
  /// **'This video file could not be read.\n\nPlease try a different file.'**
  String get invalidVideoFileBody;

  /// No description provided for @onlyMp4MovHint.
  ///
  /// In en, this message translates to:
  /// **'Only MP4 / MOV in portrait format'**
  String get onlyMp4MovHint;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @videoPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Oops! We couldn\'t play this video right now.\nPlease try again later.'**
  String get videoPlaybackError;

  /// No description provided for @confirmOwnership.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I own the rights to this content or have the necessary permission to publish it.'**
  String get confirmOwnership;

  /// No description provided for @termsAndOwnershipRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Use and confirm content ownership.'**
  String get termsAndOwnershipRequired;

  /// No description provided for @videoQuality.
  ///
  /// In en, this message translates to:
  /// **'Video Quality'**
  String get videoQuality;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @noOtherQualities.
  ///
  /// In en, this message translates to:
  /// **'No other qualities available for this video'**
  String get noOtherQualities;

  /// No description provided for @noVideosYet.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get noVideosYet;

  /// No description provided for @noVideosAvailable.
  ///
  /// In en, this message translates to:
  /// **'No videos available'**
  String get noVideosAvailable;

  /// No description provided for @youHaveNotUploadedAnyVideosYet.
  ///
  /// In en, this message translates to:
  /// **'You haven’t uploaded any videos yet.'**
  String get youHaveNotUploadedAnyVideosYet;

  /// No description provided for @creatorHasNotUploadedAnyVideosYet.
  ///
  /// In en, this message translates to:
  /// **'This creator hasn’t uploaded any videos yet.'**
  String get creatorHasNotUploadedAnyVideosYet;

  /// No description provided for @deleteVideo.
  ///
  /// In en, this message translates to:
  /// **'Delete Video'**
  String get deleteVideo;

  /// No description provided for @deleteVideoConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this video? This action cannot be undone.'**
  String get deleteVideoConfirmation;

  /// No description provided for @editDraft.
  ///
  /// In en, this message translates to:
  /// **'Edit Draft'**
  String get editDraft;

  /// No description provided for @untitledDraft.
  ///
  /// In en, this message translates to:
  /// **'Untitled Draft'**
  String get untitledDraft;

  /// No description provided for @savedToDrafts.
  ///
  /// In en, this message translates to:
  /// **'Saved to drafts'**
  String get savedToDrafts;

  /// No description provided for @noDraftsSaved.
  ///
  /// In en, this message translates to:
  /// **'No Drafts Saved'**
  String get noDraftsSaved;

  /// No description provided for @noDraftsSavedDesc.
  ///
  /// In en, this message translates to:
  /// **'Saved drafts will appear here so you can continue editing later.'**
  String get noDraftsSavedDesc;

  /// No description provided for @draftBadge.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get draftBadge;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesDesc.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save this as a draft, discard, or continue editing?'**
  String get unsavedChangesDesc;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @areYouSureDeleteVideo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this video? This action cannot be undone.'**
  String get areYouSureDeleteVideo;

  /// No description provided for @draftSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Draft saved successfully!'**
  String get draftSavedSuccessfully;

  /// No description provided for @applicationSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Application submitted successfully! Our team is reviewing it.'**
  String get applicationSubmittedSuccessfully;

  /// No description provided for @applicationTracking.
  ///
  /// In en, this message translates to:
  /// **'Application Tracking'**
  String get applicationTracking;

  /// No description provided for @applicationHistory.
  ///
  /// In en, this message translates to:
  /// **'Application History'**
  String get applicationHistory;

  /// No description provided for @submittedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Submitted Documents'**
  String get submittedDocuments;

  /// No description provided for @applicant.
  ///
  /// In en, this message translates to:
  /// **'Applicant'**
  String get applicant;

  /// No description provided for @applicantWithColon.
  ///
  /// In en, this message translates to:
  /// **'Applicant: {name}'**
  String applicantWithColon(String name);

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @destinationCountry.
  ///
  /// In en, this message translates to:
  /// **'Destination Country'**
  String get destinationCountry;

  /// No description provided for @targetIntake.
  ///
  /// In en, this message translates to:
  /// **'Target Intake'**
  String get targetIntake;

  /// No description provided for @actionRequiredFromYou.
  ///
  /// In en, this message translates to:
  /// **'Action Required from You'**
  String get actionRequiredFromYou;

  /// No description provided for @actionRequiredWithColon.
  ///
  /// In en, this message translates to:
  /// **'Action Required: {note}'**
  String actionRequiredWithColon(String note);

  /// No description provided for @pleaseProvideUpdatedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please provide the updated documents to continue processing your application.'**
  String get pleaseProvideUpdatedDocuments;

  /// No description provided for @uploadRequiredFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload Required Files'**
  String get uploadRequiredFiles;

  /// No description provided for @passportCopyLabel.
  ///
  /// In en, this message translates to:
  /// **'Passport Copy'**
  String get passportCopyLabel;

  /// No description provided for @transcriptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Transcripts'**
  String get transcriptsLabel;

  /// No description provided for @sopLabel.
  ///
  /// In en, this message translates to:
  /// **'Statement of Purpose'**
  String get sopLabel;

  /// No description provided for @recommendationLettersLabel.
  ///
  /// In en, this message translates to:
  /// **'Recommendation Letters'**
  String get recommendationLettersLabel;

  /// No description provided for @languageCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'Language Certificate'**
  String get languageCertificateLabel;

  /// No description provided for @otherDocumentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Other Documents'**
  String get otherDocumentsLabel;

  /// No description provided for @noteForAdvisorOptional.
  ///
  /// In en, this message translates to:
  /// **'Note for admission advisor (optional)...'**
  String get noteForAdvisorOptional;

  /// No description provided for @submitMissingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Submit Missing Documents'**
  String get submitMissingDocuments;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @congratulationsOfferLetterReceived.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Offer Letter Received'**
  String get congratulationsOfferLetterReceived;

  /// No description provided for @downloadOfficialAcceptanceLetter.
  ///
  /// In en, this message translates to:
  /// **'You can download your official acceptance letter'**
  String get downloadOfficialAcceptanceLetter;

  /// No description provided for @applicationNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'Application Not Accepted'**
  String get applicationNotAccepted;

  /// No description provided for @weRegretToInformYouApplicationNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'We regret to inform you that your application was not accepted.'**
  String get weRegretToInformYouApplicationNotAccepted;

  /// No description provided for @applicationProgress.
  ///
  /// In en, this message translates to:
  /// **'Application Progress'**
  String get applicationProgress;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @statusDocumentsRequired.
  ///
  /// In en, this message translates to:
  /// **'Documents Required'**
  String get statusDocumentsRequired;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing with University'**
  String get statusProcessing;

  /// No description provided for @statusProcessingCourse.
  ///
  /// In en, this message translates to:
  /// **'Processing with Course Provider'**
  String get statusProcessingCourse;

  /// No description provided for @accountAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Account Already Verified'**
  String get accountAlreadyVerified;

  /// No description provided for @youAreAlreadyLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'You are already logged in to your account.'**
  String get youAreAlreadyLoggedIn;

  /// No description provided for @resetPasswordLinkExpired.
  ///
  /// In en, this message translates to:
  /// **'Password Reset Link Expired'**
  String get resetPasswordLinkExpired;

  /// No description provided for @resetPasswordLinkExpiredDesc.
  ///
  /// In en, this message translates to:
  /// **'This password reset link is invalid or has expired. Please request a new link.'**
  String get resetPasswordLinkExpiredDesc;

  /// No description provided for @requestNewLink.
  ///
  /// In en, this message translates to:
  /// **'Request New Link'**
  String get requestNewLink;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @applicationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Application Cancelled'**
  String get applicationCancelled;

  /// No description provided for @statusUpdate.
  ///
  /// In en, this message translates to:
  /// **'Status Update'**
  String get statusUpdate;

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'file(s)'**
  String get filesCount;

  /// No description provided for @studyProgram.
  ///
  /// In en, this message translates to:
  /// **'Study Program'**
  String get studyProgram;

  /// No description provided for @studyApplication.
  ///
  /// In en, this message translates to:
  /// **'Study Application'**
  String get studyApplication;

  /// No description provided for @partnerUniversity.
  ///
  /// In en, this message translates to:
  /// **'Partner University'**
  String get partnerUniversity;

  /// No description provided for @independentCourse.
  ///
  /// In en, this message translates to:
  /// **'Independent Course'**
  String get independentCourse;

  /// No description provided for @documentsSubmittedForReviewSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Documents submitted for review successfully!'**
  String get documentsSubmittedForReviewSuccessfully;

  /// No description provided for @pleaseCompleteAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields'**
  String get pleaseCompleteAllRequiredFields;

  /// No description provided for @dateOfBirthIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Date of birth is required'**
  String get dateOfBirthIsRequired;

  /// No description provided for @applyWithSkyViora.
  ///
  /// In en, this message translates to:
  /// **'Apply with SKY VIORA'**
  String get applyWithSkyViora;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @step1PersonalInformation.
  ///
  /// In en, this message translates to:
  /// **'1. Personal Information'**
  String get step1PersonalInformation;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @firstName2.
  ///
  /// In en, this message translates to:
  /// **'First Name *'**
  String get firstName2;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @dateOfBirthYyyymmdd.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth (YYYY-MM-DD) *'**
  String get dateOfBirthYyyymmdd;

  /// No description provided for @passportNumber2.
  ///
  /// In en, this message translates to:
  /// **'Passport Number'**
  String get passportNumber2;

  /// No description provided for @passportExpiry.
  ///
  /// In en, this message translates to:
  /// **'Passport Expiry'**
  String get passportExpiry;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailAddress2.
  ///
  /// In en, this message translates to:
  /// **'Email Address *'**
  String get emailAddress2;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @phoneNumber2.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumber2;

  /// No description provided for @step2AcademicHistory.
  ///
  /// In en, this message translates to:
  /// **'2. Academic History'**
  String get step2AcademicHistory;

  /// No description provided for @lastSchoolInstitutionAttended.
  ///
  /// In en, this message translates to:
  /// **'Last School / Institution Attended'**
  String get lastSchoolInstitutionAttended;

  /// No description provided for @previousInstitution.
  ///
  /// In en, this message translates to:
  /// **'Previous Institution'**
  String get previousInstitution;

  /// No description provided for @gradeGpaEg85.
  ///
  /// In en, this message translates to:
  /// **'Grade / GPA (e.g. 85%)'**
  String get gradeGpaEg85;

  /// No description provided for @gradeAverage.
  ///
  /// In en, this message translates to:
  /// **'Grade Average'**
  String get gradeAverage;

  /// No description provided for @graduationYear.
  ///
  /// In en, this message translates to:
  /// **'Graduation Year'**
  String get graduationYear;

  /// No description provided for @step3DocumentUploads.
  ///
  /// In en, this message translates to:
  /// **'3. Document Uploads'**
  String get step3DocumentUploads;

  /// No description provided for @uploadClearPdfOrImageFilesPngjpg.
  ///
  /// In en, this message translates to:
  /// **'Upload clear PDF or image files (PNG/JPG)'**
  String get uploadClearPdfOrImageFilesPngjpg;

  /// No description provided for @passportCopy.
  ///
  /// In en, this message translates to:
  /// **'Passport Copy'**
  String get passportCopy;

  /// No description provided for @academicTranscriptsCertificates.
  ///
  /// In en, this message translates to:
  /// **'Academic Transcripts & Certificates'**
  String get academicTranscriptsCertificates;

  /// No description provided for @statementOfPurposeSop.
  ///
  /// In en, this message translates to:
  /// **'Statement of Purpose (SOP)'**
  String get statementOfPurposeSop;

  /// No description provided for @resumeCv.
  ///
  /// In en, this message translates to:
  /// **'Resume / CV'**
  String get resumeCv;

  /// No description provided for @saveAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as Draft'**
  String get saveAsDraft;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// No description provided for @countryOfCitizenship.
  ///
  /// In en, this message translates to:
  /// **'Country of citizenship *'**
  String get countryOfCitizenship;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @fileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded'**
  String get fileUploaded;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @searchCountry.
  ///
  /// In en, this message translates to:
  /// **'Search country...'**
  String get searchCountry;

  /// No description provided for @myStudyApplications.
  ///
  /// In en, this message translates to:
  /// **'My Study Applications'**
  String get myStudyApplications;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @noApplicationsFound.
  ///
  /// In en, this message translates to:
  /// **'No applications found'**
  String get noApplicationsFound;

  /// No description provided for @startDiscoveringProgramsAndApplyDirectlyWithSkyViora.
  ///
  /// In en, this message translates to:
  /// **'Start discovering programs and apply directly with SKY VIORA'**
  String get startDiscoveringProgramsAndApplyDirectlyWithSkyViora;

  /// No description provided for @explorePrograms.
  ///
  /// In en, this message translates to:
  /// **'Explore Programs'**
  String get explorePrograms;

  /// No description provided for @continueDraft.
  ///
  /// In en, this message translates to:
  /// **'Continue Draft'**
  String get continueDraft;

  /// No description provided for @trackStatus.
  ///
  /// In en, this message translates to:
  /// **'Track Status'**
  String get trackStatus;

  /// No description provided for @studyProfile.
  ///
  /// In en, this message translates to:
  /// **'Study Profile'**
  String get studyProfile;

  /// No description provided for @completeYourStudyProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your Study Profile'**
  String get completeYourStudyProfile;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @editStudyProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Study Profile'**
  String get editStudyProfile;

  /// No description provided for @updateStudyPreferences.
  ///
  /// In en, this message translates to:
  /// **'Update your study preferences to get better recommendations.'**
  String get updateStudyPreferences;

  /// No description provided for @degree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get degree;

  /// No description provided for @selectDegree.
  ///
  /// In en, this message translates to:
  /// **'Select Degree'**
  String get selectDegree;

  /// No description provided for @preferredCountry.
  ///
  /// In en, this message translates to:
  /// **'Preferred Country'**
  String get preferredCountry;

  /// No description provided for @preferredField.
  ///
  /// In en, this message translates to:
  /// **'Preferred Field'**
  String get preferredField;

  /// No description provided for @selectField.
  ///
  /// In en, this message translates to:
  /// **'Select Field'**
  String get selectField;

  /// No description provided for @preferredSpecialisation.
  ///
  /// In en, this message translates to:
  /// **'Preferred Specialisation'**
  String get preferredSpecialisation;

  /// No description provided for @selectSpecialisation.
  ///
  /// In en, this message translates to:
  /// **'Select Specialisation'**
  String get selectSpecialisation;

  /// No description provided for @selectTargetIntake.
  ///
  /// In en, this message translates to:
  /// **'Select Target Intake'**
  String get selectTargetIntake;

  /// No description provided for @studyGoals.
  ///
  /// In en, this message translates to:
  /// **'Study Goals'**
  String get studyGoals;

  /// No description provided for @tapToSetStudyGoals.
  ///
  /// In en, this message translates to:
  /// **'Tap to set study goals'**
  String get tapToSetStudyGoals;

  /// No description provided for @editStudyGoals.
  ///
  /// In en, this message translates to:
  /// **'Edit Study Goals'**
  String get editStudyGoals;

  /// No description provided for @enterStudyGoals.
  ///
  /// In en, this message translates to:
  /// **'Enter your study goals...'**
  String get enterStudyGoals;

  /// No description provided for @otherPreferredCountries.
  ///
  /// In en, this message translates to:
  /// **'Other Preferred Countries'**
  String get otherPreferredCountries;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @multiCountryHint.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple countries that you are interested in studying in.'**
  String get multiCountryHint;

  /// No description provided for @studyProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Study Profile updated successfully!'**
  String get studyProfileUpdated;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @addStudyPreferencesHint.
  ///
  /// In en, this message translates to:
  /// **'Add your study preferences to get better recommendations and support.'**
  String get addStudyPreferencesHint;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @yourStudyPlanAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Your study plan at a glance'**
  String get yourStudyPlanAtAGlance;

  /// No description provided for @keepStudyProfileUpdatedHint.
  ///
  /// In en, this message translates to:
  /// **'Keep your study profile updated to get better recommendations and support.'**
  String get keepStudyProfileUpdatedHint;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your account. Ensure it is strong and secure.'**
  String get changePasswordSubtitle;

  /// No description provided for @changeEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new email address. We will send a verification link to confirm it.'**
  String get changeEmailSubtitle;

  /// No description provided for @changePhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new phone number. We will send a 6-digit verification code to confirm it.'**
  String get changePhoneSubtitle;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @extractingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Extracting Metadata...'**
  String get extractingMetadata;

  /// No description provided for @addToReadinglist.
  ///
  /// In en, this message translates to:
  /// **'Add to readinglist'**
  String get addToReadinglist;

  /// No description provided for @algorithmDebugger.
  ///
  /// In en, this message translates to:
  /// **'Algorithm Debugger'**
  String get algorithmDebugger;

  /// No description provided for @algorithmDebuggerDev.
  ///
  /// In en, this message translates to:
  /// **'Algorithm Debugger (Dev)'**
  String get algorithmDebuggerDev;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you Sure'**
  String get areYouSure;

  /// No description provided for @areYouSureYouWantToExitTheApplication.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the application?'**
  String get areYouSureYouWantToExitTheApplication;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @checkBackLaterForNewContent.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new content!'**
  String get checkBackLaterForNewContent;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy Message'**
  String get copyMessage;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @ddMmYyyy.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get ddMmYyyy;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @exitApplication.
  ///
  /// In en, this message translates to:
  /// **'Exit Application'**
  String get exitApplication;

  /// No description provided for @filterDestinations.
  ///
  /// In en, this message translates to:
  /// **'Filter Destinations'**
  String get filterDestinations;

  /// No description provided for @findingBestProgramMatches.
  ///
  /// In en, this message translates to:
  /// **'Finding best program matches...'**
  String get findingBestProgramMatches;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @landmarks.
  ///
  /// In en, this message translates to:
  /// **'Landmarks:'**
  String get landmarks;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// No description provided for @loginToViewYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Login to view your profile'**
  String get loginToViewYourProfile;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No followers yet.'**
  String get noFollowersYet;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get noHistoryYet;

  /// No description provided for @noLikesYet.
  ///
  /// In en, this message translates to:
  /// **'No likes yet'**
  String get noLikesYet;

  /// No description provided for @noRepliesYetSupportTeamWillRespondShortly.
  ///
  /// In en, this message translates to:
  /// **'No replies yet. Support team will respond shortly.'**
  String get noRepliesYetSupportTeamWillRespondShortly;

  /// No description provided for @noScoringDebugDataAvailableForThisVideo.
  ///
  /// In en, this message translates to:
  /// **'No scoring debug data available for this video.'**
  String get noScoringDebugDataAvailableForThisVideo;

  /// No description provided for @notFollowingAnyone.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone.'**
  String get notFollowingAnyone;

  /// No description provided for @passportJohnJpg.
  ///
  /// In en, this message translates to:
  /// **'Passport_john.jpg'**
  String get passportJohnJpg;

  /// No description provided for @previewUnavailableOnThisDeviceNFileIsValidAndCanStillBeUploaded.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable on this device\n(File is valid and can still be uploaded)'**
  String get previewUnavailableOnThisDeviceNFileIsValidAndCanStillBeUploaded;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @processingVideo.
  ///
  /// In en, this message translates to:
  /// **'Processing Video...'**
  String get processingVideo;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @rateOurVisaService.
  ///
  /// In en, this message translates to:
  /// **'Rate Our Visa Service'**
  String get rateOurVisaService;

  /// No description provided for @rateService.
  ///
  /// In en, this message translates to:
  /// **'Rate Service'**
  String get rateService;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyingToWidgetReplyingtoUserNameUser.
  ///
  /// In en, this message translates to:
  /// **'Replying to @{user}'**
  String replyingToWidgetReplyingtoUserNameUser(String user);

  /// No description provided for @reportPlaybackIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Playback Issue'**
  String get reportPlaybackIssue;

  /// No description provided for @skyviora.
  ///
  /// In en, this message translates to:
  /// **'SKYVIORA'**
  String get skyviora;

  /// No description provided for @saveToSavedVideos.
  ///
  /// In en, this message translates to:
  /// **'Save to Saved Videos'**
  String get saveToSavedVideos;

  /// No description provided for @selectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select {title}'**
  String selectTitle(String title);

  /// No description provided for @shareThisVideo.
  ///
  /// In en, this message translates to:
  /// **'Share this video'**
  String get shareThisVideo;

  /// No description provided for @totalScore.
  ///
  /// In en, this message translates to:
  /// **'TOTAL SCORE'**
  String get totalScore;

  /// No description provided for @thankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get thankYou;

  /// No description provided for @thisTicketIsClosedMessagingIsDisabledUntilItIsReopenedBySupport.
  ///
  /// In en, this message translates to:
  /// **'This ticket is closed. Messaging is disabled until it is reopened by support.'**
  String get thisTicketIsClosedMessagingIsDisabledUntilItIsReopenedBySupport;

  /// No description provided for @videoIsReady.
  ///
  /// In en, this message translates to:
  /// **'Video is ready!'**
  String get videoIsReady;

  /// No description provided for @writeYourFeedbackOptional.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback (optional)...'**
  String get writeYourFeedbackOptional;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @youWantToLogout.
  ///
  /// In en, this message translates to:
  /// **'You Want to Logout?'**
  String get youWantToLogout;

  /// No description provided for @youCanOnlySelectUpToWidgetMaxselectCountries.
  ///
  /// In en, this message translates to:
  /// **'You can only select up to {maxSelect} countries'**
  String youCanOnlySelectUpToWidgetMaxselectCountries(int maxSelect);

  /// No description provided for @youMustBeLoggedInToChatWithTheSkyvioraAiAssistantAndSaveYourSessions.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to chat with the SkyViora AI Assistant and save your sessions.'**
  String
  get youMustBeLoggedInToChatWithTheSkyvioraAiAssistantAndSaveYourSessions;

  /// No description provided for @yourVisaProcessIsCompletePleaseLetUsKnowHowSatisfiedYouWereWithOurService.
  ///
  /// In en, this message translates to:
  /// **'Your visa process is complete. Please let us know how satisfied you were with our service.'**
  String
  get yourVisaProcessIsCompletePleaseLetUsKnowHowSatisfiedYouWereWithOurService;

  /// No description provided for @exampleEmailCom.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get exampleEmailCom;

  /// No description provided for @makePublic.
  ///
  /// In en, this message translates to:
  /// **'Make Public'**
  String get makePublic;

  /// No description provided for @makePrivate.
  ///
  /// In en, this message translates to:
  /// **'Make Private'**
  String get makePrivate;

  /// No description provided for @makeVideoPublicConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to make this video public? It will be visible on your profile and feed.'**
  String get makeVideoPublicConfirmation;

  /// No description provided for @makeVideoPrivateConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to make this video private? It will be hidden from your profile and feed.'**
  String get makeVideoPrivateConfirmation;

  /// No description provided for @ticketIsClosed.
  ///
  /// In en, this message translates to:
  /// **'Ticket is closed'**
  String get ticketIsClosed;

  /// No description provided for @selectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Photo'**
  String get selectPhoto;

  /// No description provided for @selectVideoSource.
  ///
  /// In en, this message translates to:
  /// **'Select Video Source'**
  String get selectVideoSource;

  /// No description provided for @fileLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileLabel;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @initial.
  ///
  /// In en, this message translates to:
  /// **'Initial'**
  String get initial;

  /// No description provided for @addAReply.
  ///
  /// In en, this message translates to:
  /// **'Add a reply...'**
  String get addAReply;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to @{username}'**
  String replyingTo(String username);

  /// No description provided for @noRecents.
  ///
  /// In en, this message translates to:
  /// **'No Recents'**
  String get noRecents;

  /// No description provided for @pleaseUploadRequiredDocs.
  ///
  /// In en, this message translates to:
  /// **'Please upload the required documents.'**
  String get pleaseUploadRequiredDocs;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach Image'**
  String get attachImage;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccess;

  /// No description provided for @phoneVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully!'**
  String get phoneVerifiedSuccess;

  /// No description provided for @pleaseEnter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit verification code.'**
  String get pleaseEnter6DigitCode;

  /// No description provided for @tapLinkOrEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Tap the link in your email, or enter the 6-digit code:'**
  String get tapLinkOrEnterCode;

  /// No description provided for @checkPhoneForCode.
  ///
  /// In en, this message translates to:
  /// **'Please check your phone for a 6-digit code.'**
  String get checkPhoneForCode;

  /// No description provided for @checkEmailForCode.
  ///
  /// In en, this message translates to:
  /// **'Please check your email for a 6-digit code.'**
  String get checkEmailForCode;

  /// No description provided for @verificationFor.
  ///
  /// In en, this message translates to:
  /// **'Verification for '**
  String get verificationFor;

  /// No description provided for @yourEmail.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get yourEmail;

  /// No description provided for @signUpSuccessCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Sign up successful! Please check your inbox to verify your email.'**
  String get signUpSuccessCheckInbox;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
