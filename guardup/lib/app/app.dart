import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ignore: depend_on_referenced_packages
import 'package:material_ui/material_ui.dart' as mui;

import '/app/routes/app_router.dart';
import '/app/theme/app_theme.dart';
import '/core/config/config.dart';
import '/core/di/injection_container.dart';
import '/features/auth/auth.dart';
import '/features/notifications/notifications.dart';
import '/gen/app_localizations.dart';
import '/gen/assets.gen.dart';
import '/shared/functionalities/connectivity/connectivity.dart';
import '/shared/functionalities/language/language.dart';
import '/shared/widgets/feedbacks/feedback.service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<LanguageCubit>(create: (_) => sl<LanguageCubit>()),
        BlocProvider<ConnectivityCubit>(create: (_) => sl<ConnectivityCubit>()),
        BlocProvider<UnreadNotificationCountCubit>.value(
          value: sl<UnreadNotificationCountCubit>(),
        ),
        BlocProvider<UserDeviceCubit>.value(
          value: sl<UserDeviceCubit>(),
        ),
      ],
      child: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, languageState) {
          return MaterialApp.router(
            title: AppEnvironment.config.appName,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: languageState.locale,
            themeMode: ThemeMode.system,
            scaffoldMessengerKey: FeedbackService.messengerKey,
            // localizationsDelegates: const [
            //   AppLocalizations.delegate,
            //   GlobalMaterialLocalizations.delegate,
            //   GlobalWidgetsLocalizations.delegate,
            //   GlobalCupertinoLocalizations.delegate,
            // ],
            // inside MaterialApp.router
            localizationsDelegates: const [
              AppLocalizations.delegate,
              mui.DefaultMaterialLocalizations.delegate, // add this
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      Assets.images.background.path,
                      fit: BoxFit.cover,
                    ),
                  ),
                  ?child,
                  const Align(
                    alignment: Alignment.topCenter,
                    child: NoInternetBanner(),
                  ),
                  const Align(
                    alignment: Alignment.topCenter,
                    child: ForegroundNotificationBanner(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
