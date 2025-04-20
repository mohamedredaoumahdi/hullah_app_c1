import 'package:go_router/go_router.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/measurements/screens/measurements_input_screen.dart';
import '../../features/measurements/screens/image_upload_screen.dart';
import '../../features/measurements/screens/body_analysis_screen.dart';
import '../../features/abayas/screens/abaya_selection_screen.dart';
import '../../features/abayas/screens/abaya_details_screen.dart';
import '../../features/summary/screens/my_summary_screen.dart';
import '../../features/summary/screens/final_summary_screen.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/thank_you/screens/thank_you_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/measurements/input',
        builder: (context, state) => const MeasurementsInputScreen(),
      ),
      GoRoute(
        path: '/measurements/upload',
        builder: (context, state) => const ImageUploadScreen(),
      ),
      GoRoute(
        path: '/measurements/analysis',
        builder: (context, state) => const BodyAnalysisScreen(),
      ),
      GoRoute(
        path: '/abayas/selection',
        builder: (context, state) => const AbayaSelectionScreen(),
      ),
      GoRoute(
        path: '/abayas/details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AbayaDetailsScreen(abayaId: id);
        },
      ),
      GoRoute(
        path: '/summary',
        builder: (context, state) => const MySummaryScreen(),
      ),
      GoRoute(
        path: '/summary/final',
        builder: (context, state) => const FinalSummaryScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/thank-you',
        builder: (context, state) => const ThankYouScreen(),
      ),
    ],
  );
}