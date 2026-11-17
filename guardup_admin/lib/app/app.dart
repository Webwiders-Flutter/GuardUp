import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/gen/app_localizations.dart';

import '/app/routes/app_router.dart';
import '/core/config/config.dart';
import '/shared/widgets/feedbacks/feedback.service.dart';
import '/shared/widgets/connectivity/internet_connectivity.widget.dart';
import '/features/notifications/presentation/widgets/foreground_notification_banner.widget.dart';
import '/core/providers/theme/theme.provider.dart';
import '/app/theme/app_theme.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_quill/flutter_quill.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(AppRouter.goRouterProvider);
    final themeMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.system;

    return MaterialApp.router(
      title: AppEnvironment.config.appName,
      debugShowCheckedModeBanner: false,

      routerConfig: router,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      scaffoldMessengerKey: FeedbackService.messengerKey,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [Locale('en')],

      builder: (_, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NoInternetBanner(),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ForegroundNotificationBanner(),
            ),
          ],
        );
      },
    );
  }
}
