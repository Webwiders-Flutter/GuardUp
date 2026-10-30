import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/ui_feedback.dart';
import 'package:guardup/features/help_centre/domain/repositories/support_repository.dart';

class DeepLinkHandler {
  static Future<void> handle(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);

      if (uri.host == 'my_tickets') {
        context.pushNamed(AppRouter.myTickets);
        return;
      }
      if (uri.host == 'create_ticket') {
        context.pushNamed(AppRouter.createTicket);
        return;
      }
      if (uri.host == 'privacy_policy') {
        context.pushNamed(AppRouter.privacyPolicyScreen);
        return;
      }
      if (uri.host == 'terms_and_conditions') {
        context.pushNamed(AppRouter.termsAndConditionScreen);
        return;
      }
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      final hasError =
          uri.queryParameters.containsKey('error') ||
          uri.queryParameters.containsKey('error_code') ||
          fragmentParams.containsKey('error') ||
          fragmentParams.containsKey('error_code');

      final isAuthCallback =
          uri.host == 'auth-callback' ||
          (uri.host == 'skyviora.com' && uri.path == '/auth-callback');

      if (!hasError &&
          (uri.host == 'reset-password' ||
              uri.host == 'create-new-password' ||
              (isAuthCallback &&
                  (uri.queryParameters['type'] == 'recovery' ||
                      fragmentParams['type'] == 'recovery')))) {
        context.goNamed(AppRouter.createNewPassword);
        return;
      }

      if (isAuthCallback) {
        final type = uri.queryParameters['type'] ?? fragmentParams['type'];
        final error = uri.queryParameters['error'] ?? fragmentParams['error'];
        final errorCode =
            uri.queryParameters['error_code'] ?? fragmentParams['error_code'];
        final errorDesc =
            uri.queryParameters['error_description'] ??
            fragmentParams['error_description'];
        context.go(
          Uri(
            path: AppRouter.loginCallback,
            queryParameters: {
              'type': ?type,
              'error': ?error,
              'error_code': ?errorCode,
              'error_description': ?errorDesc,
            },
          ).toString(),
        );
        return;
      }

      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      if (id == null) return;

      if (uri.host == 'ticket') {
        UIFeedback.showSnackbar(context, "Loading ticket details...");
        final result = await sl<SupportRepository>().getTicketById(id);

        if (context.mounted) {
          result.fold(
            (failure) => UIFeedback.showSnackbar(context, failure.message),
            (ticket) =>
                context.pushNamed(AppRouter.ticketDetail, extra: ticket),
          );
        }
      }
    } catch (e) {
      AppLogs.error("Error handling deep link", error: e);
    }
  }
}
