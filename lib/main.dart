import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:safe_device/safe_device.dart';
import 'core/theme/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/idle_timeout_wrapper.dart';
import 'features/auth/presentation/providers/auth_controller.dart';
import 'features/expert/presentation/providers/notes_controller.dart';
import 'features/settings/presentation/providers/settings_controller.dart';

import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_translations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase App Check (Native backend hardware security)
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerApple: const AppleAppAttestProvider(),
      providerAndroid: const AndroidPlayIntegrityProvider(),
    );
  }

  // Initialize GetX Controllers
  Get.put(AuthController());
  Get.put(ThemeController());
  Get.put(NotesController());
  Get.put(SettingsController());

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppWithRouter();
  }
}

class AppWithRouter extends StatefulWidget {
  const AppWithRouter({super.key});

  @override
  State<AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<AppWithRouter> {
  late GoRouter _router;
  bool _jailbroken = false;
  bool _jailbreakChecked = false;

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    _router = AppRouter(authController).router;
    _checkJailbreak();
  }

  Future<void> _checkJailbreak() async {
    try {
      // Jailbreak detection is only available/meaningful on mobile devices
      final isMobile = defaultTargetPlatform == TargetPlatform.android ||
                       defaultTargetPlatform == TargetPlatform.iOS;
                       
      if (kIsWeb || !isMobile) {
        if (mounted) setState(() => _jailbreakChecked = true);
        return;
      }

      final isJailBroken = await SafeDevice.isJailBroken;
      final jailbroken = isJailBroken;
      if (mounted) {
        setState(() {
          _jailbroken = jailbroken;
          _jailbreakChecked = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _jailbreakChecked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    final settingsController = Get.find<SettingsController>();

    return Obx(() => GetMaterialApp.router(
          title: 'Intellix',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerDelegate: _router.routerDelegate,
          routeInformationParser: _router.routeInformationParser,
          routeInformationProvider: _router.routeInformationProvider,
          translations: AppTranslations(),
          locale: Locale(settingsController.currentLanguage.value),
          fallbackLocale: const Locale('en'),
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
            Locale('ckb'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            // Idle Session Timeout wraps the entire app
            Widget content = IdleTimeoutWrapper(
              timeout: const Duration(minutes: 15),
              child: child ?? const SizedBox.shrink(),
            );

            // Jailbreak warning overlay (shown only on compromised devices)
            if (_jailbreakChecked && _jailbroken) {
              content = Stack(
                children: [
                  content,
                  _JailbreakWarningOverlay(
                      onDismiss: () => setState(() => _jailbroken = false)),
                ],
              );
            }

            return content;
          },
        ));
  }
}

/// Full-screen overlay warning shown when a jailbroken/rooted device is detected.
class _JailbreakWarningOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _JailbreakWarningOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.92),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.security_rounded,
                      color: Colors.red, size: 56),
                ),
                const SizedBox(height: 24),
                const Text(
                  '⚠️ Security Warning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This device appears to be rooted or jailbroken. '
                  'Running Intellix on a compromised device puts your '
                  'financial data and account security at serious risk.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'I Understand — Continue Anyway',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
