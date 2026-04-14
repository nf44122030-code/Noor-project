import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_page.dart';
import '../../features/auth/presentation/screens/signup_page.dart';
import '../../features/auth/presentation/screens/forgot_password_page.dart';
import '../../features/auth/presentation/screens/email_verification_page.dart';
import '../../features/auth/presentation/screens/splash_page.dart';
import '../../features/auth/presentation/screens/intro_page.dart';
import '../../features/home/presentation/screens/home_page.dart';
import '../../features/profile/presentation/screens/profile_page.dart';
import '../../features/settings/presentation/screens/settings_page.dart';
import '../../features/expert/presentation/screens/expert_session_page.dart';
import '../../features/expert/presentation/screens/video_session_page.dart';
import '../../features/expert/presentation/screens/notes_history_page.dart';
import '../../features/expert/presentation/screens/session_notes_page.dart';
import '../../features/expert/presentation/screens/my_bookings_page.dart';
import '../../features/trends/presentation/screens/trends_page.dart';
import '../../features/support/presentation/screens/help_page.dart';
import '../../features/subscription/presentation/screens/pricing_page.dart';
import '../../features/info/presentation/screens/what_is_intellix_page.dart';
import '../../features/notification/presentation/screens/notification_page.dart';
import '../../features/expert_portal/presentation/screens/expert_dashboard_page.dart';

class AppRouter {
  final AuthController authController;

  AppRouter(this.authController);

  late final GoRouter router = GoRouter(
    refreshListenable: authController.routerRefreshListenable,
    redirect: (context, state) {
      if (authController.isLoading) return null;

      final isLoggedIn       = authController.isAuthenticated;
      final isEmailVerified  = authController.isEmailVerified;
      final path             = state.uri.path;

      final isAuthPath   = path == '/login' || path == '/signup' || path == '/forgot-password';
      final isVerifyPath = path == '/verify-email';
      final isSplashPath = path == '/splash';
      final isIntroPath  = path == '/intro';
      final isRootPath   = path == '/';

      // Always allow the splash screen, intro screen, and root to finish/trigger animation
      if (isSplashPath || isIntroPath || isRootPath) return null;

      final isExpertMode = authController.isExpertMode;
      final targetHome   = isExpertMode ? '/expert-dashboard' : '/home';

      // Not logged in → send to login (unless already on auth screen)
      if (!isLoggedIn && !isAuthPath) return '/login';

      // Logged in + on auth screen → redirect appropriately
      if (isLoggedIn && isAuthPath) {
        final isGuest = authController.isGuest;
        return (isEmailVerified || isGuest) ? targetHome : '/verify-email';
      }

      // Logged in but email not verified (and not a guest) → verify-email only
      if (isLoggedIn && !isEmailVerified && !authController.isGuest && !isVerifyPath) return '/verify-email';

      // Logged in, verified (or guest), sitting on verify-email page → move to home
      if (isLoggedIn && (isEmailVerified || authController.isGuest) && isVerifyPath) return targetHome;
      
      // If Expert tries to access standard client app (/home), force them back to portal
      if (isLoggedIn && isExpertMode && path == '/home') return '/expert-dashboard';
      if (isLoggedIn && !isExpertMode && path == '/expert-dashboard') return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const IntroScreens(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/expert-session',
        builder: (context, state) => const ExpertSessionPage(),
      ),
      GoRoute(
        path: '/video-session',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return VideoSessionPage(
            expertName: extras?['expertName'],
            expertTitle: extras?['expertTitle'],
            initialCode: extras?['initialCode'],
          );
        },
      ),
      GoRoute(
        path: '/my-bookings',
        builder: (context, state) => const MyBookingsPage(),
      ),
      GoRoute(
        path: '/notes-history',
        builder: (context, state) => const NotesHistoryPage(),
      ),
      GoRoute(
        path: '/session-notes/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SessionNotesPage(sessionId: id);
        },
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => const TrendsPage(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: '/pricing',
        builder: (context, state) => const PricingPage(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const WhatIsIntellixPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(
        path: '/expert-dashboard',
        builder: (context, state) => const ExpertDashboardPage(),
      ),
    ],
  );
}
