class ErrorKeys {
  ErrorKeys._(); // Private constructor to prevent instantiation

  static const String server = 'errorServer';
  static const String userNotAuthenticated = 'errorUserNotAuthenticated';
  static const String failedToLoadData = 'errorFailedToLoadData';
  static const String failedToUpdate = 'errorFailedToUpdate';
  static const String failedToDelete = 'errorFailedToDelete';
  static const String failedToUpload = 'errorFailedToUpload';
  static const String connectionTimedOut = 'errorConnectionTimedOut';
  static const String resourceNotFound = 'errorResourceNotFound';
  static const String invalidFileType = 'errorInvalidFileType';
  static const String requestCancelled = 'errorRequestCancelled';
  static const String alreadyReported = 'errorAlreadyReported';
}
