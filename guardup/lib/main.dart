import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guardup/core/constants/env_config.dart';
import 'package:guardup/core/localization/locale_bloc.dart';
import 'package:guardup/core/network/connectivity_bloc.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/services/push_notification_service.dart';
import 'package:guardup/core/theme/app_themes.dart';
import 'package:guardup/core/theme/theme_bloc.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/widgets/app_phone_textfield/app_phone_textfield.dart';
import 'package:guardup/core/widgets/common/no_internet_screen.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:guardup/features/help_centre/presentation/bloc/support_cubit.dart';
import 'package:guardup/features/locations/presentation/bloc/country_bloc/country_bloc.dart';
import 'package:guardup/features/notifications/presentation/bloc/notification_bloc.dart'
    as guard_noti;
import 'package:guardup/features/notifications/presentation/bloc/notification_event.dart'
    as guard_noti;
import 'package:guardup/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Initialize Dependency Injection
  await initDI();
  await PhoneNumberServices.init();

  // 2. Initialize Environment Variables
  await EnvConfig.init();

  // Initialize Date Formatting for Arabic
  await initializeDateFormatting('ar', null);

  // 3. Initialize Supabase
  if (EnvConfig.supabaseUrl.isNotEmpty &&
      EnvConfig.supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('⚠️ Supabase initialization failed: $e');
    }
  } else {
    debugPrint(
      'ℹ️ Supabase URL or Anon Key is empty in .env. Initialization deferred.',
    );
  }

  // 4. Initialize Push Notifications
  try {
    await sl<PushNotificationService>().init();
  } catch (e) {
    debugPrint(
      'ℹ️ Push notification service initialization skipped/deferred: $e',
    );
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ThemeBloc>()..add(const LoadTheme()),
        ),
        BlocProvider(create: (context) => sl<ConnectivityBloc>()),
        BlocProvider(
          create: (context) => sl<LocaleBloc>()..add(const LoadLocale()),
        ),
        BlocProvider(create: (context) => sl<AuthBloc>()),
        BlocProvider(create: (context) => sl<CountryBloc>()),
        BlocProvider(create: (context) => sl<SupportCubit>()),
        BlocProvider(
          create: (context) => sl<guard_noti.NotificationBloc>()
            ..add(const guard_noti.FetchNotificationsEvent(isRefresh: true)),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            curr is AuthenticatedState && prev is! AuthenticatedState,
        listener: (context, state) {},
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _handleSharingIntents();
  }

  void _handleSharingIntents() {
    AppLogs.debugPrint(
      ">>> [SharingIntent] Setting up ReceiveSharingIntent listeners...",
    );

    // Listen to media shared while app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            AppLogs.debugPrint(
              ">>> [SharingIntent] Stream received ${value.length} files",
            );
            for (final f in value) {
              AppLogs.debugPrint(
                ">>> [SharingIntent] Stream file: path=${f.path}, type=${f.type}, mime=${f.mimeType}",
              );
            }
            _processSharedMedia(value);
          },
          onError: (err) {
            AppLogs.debugPrint(">>> [SharingIntent] Stream error: $err");
          },
        );

    // Listen to media shared while app is closed (cold launch)
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
          AppLogs.debugPrint(
            ">>> [SharingIntent] Initial received ${value.length} files",
          );
          for (final f in value) {
            AppLogs.debugPrint(
              ">>> [SharingIntent] Initial file: path=${f.path}, type=${f.type}, mime=${f.mimeType}",
            );
          }
          _processSharedMedia(value);
          ReceiveSharingIntent.instance.reset();
        })
        .catchError((err) {
          AppLogs.debugPrint(">>> [SharingIntent] getInitialMedia error: $err");
        });
  }

  void _processSharedMedia(List<SharedMediaFile> files) {
    AppLogs.debugPrint(
      ">>> [SharingIntent] _processSharedMedia with ${files.length} files",
    );
    if (files.isEmpty) return;

    final file = files.first;
    AppLogs.debugPrint(
      ">>> [SharingIntent] First file path: ${file.path}, type: ${file.type}, mime: ${file.mimeType}",
    );

    final String pathLower = file.path.toLowerCase();

    if (file.type == SharedMediaType.url ||
        file.type == SharedMediaType.text ||
        pathLower.startsWith('http')) {
      AppLogs.debugPrint(
        ">>> [SharingIntent] Ignored because it's a URL or Text (deep link), not a local video file.",
      );
      return;
    }

    final bool isVideoExt =
        pathLower.endsWith('.mp4') ||
        pathLower.endsWith('.mov') ||
        pathLower.endsWith('.mkv') ||
        pathLower.endsWith('.avi') ||
        pathLower.endsWith('.3gp') ||
        pathLower.endsWith('.webm');

    final bool isVideoMime =
        file.mimeType != null && file.mimeType!.startsWith('video/');

    final bool isVideo =
        file.type == SharedMediaType.video ||
        file.type == SharedMediaType.file ||
        isVideoExt ||
        isVideoMime;

    if (isVideo) {
      final videoPath = file.path;
      AppLogs.debugPrint(
        ">>> [SharingIntent] Valid video file detected: $videoPath",
      );
    } else {
      AppLogs.debugPrint(
        ">>> [SharingIntent] File rejected - not recognized as video: type=${file.type}, path=${file.path}",
      );
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LocaleBloc, LocaleState>(
          builder: (context, localeState) {
            return ResponsiveSizer(
              builder: (p0, p1, p2) {
                return MaterialApp.router(
                  title: EnvConfig.appName,
                  debugShowCheckedModeBanner: EnvConfig.isDebug,

                  // Theme
                  theme: AppThemes.light,
                  darkTheme: AppThemes.dark,
                  themeMode: themeState.themeMode,

                  // Localization
                  locale: localeState.locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    CountryLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  // Router
                  routerConfig: AppRouter.router,

                  builder: (context, child) {
                    return UpgradeAlert(
                      upgrader: Upgrader(debugDisplayAlways: false),
                      navigatorKey:
                          AppRouter.router.routerDelegate.navigatorKey,
                      child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
                        builder: (context, state) {
                          return Directionality(
                            textDirection: Directionality.of(context),
                            child: (state is ConnectivityOffline)
                                ? const NoInternetScreen()
                                : child ?? const SizedBox.shrink(),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
