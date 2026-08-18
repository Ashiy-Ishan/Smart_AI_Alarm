import 'package:alarm_frontend/providers/user_provider.dart';
import 'package:alarm_frontend/utils/app_colors.dart';
import 'package:alarm_frontend/components/primary_button.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  bool _redirected = false;

  // fast redirect if already logged in
  void _checkAuthStatus() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    void checkAndRedirect() {
      if (userProvider.isAuthenticated && mounted && !_redirected) {
        _redirected = true;
        // Prevent multiple pushes if listener fires again
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    }

    if (userProvider.isInitialized) {
      checkAndRedirect();
    }
    
    userProvider.addListener(() {
      if (mounted && userProvider.isInitialized) {
        checkAndRedirect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // black screen during sub-second redirect
    if (userProvider.isInitialized && userProvider.isAuthenticated) {
      return Scaffold(backgroundColor: theme.scaffoldBackgroundColor);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox.shrink(),

                      // App Logo (SVG)
                      Column(
                        children: [
                          Container(
                            height: constraints.maxHeight * 0.25,
                            padding: const EdgeInsets.all(16),
                            child: SvgPicture.asset(
                              'assets/icon/icon.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Smarter Wake-Ups,\nBetter Days.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),

                      if (!userProvider.isInitialized)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 64.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      else
                        Column(
                          children: [
                            PrimaryButton(
                              text: 'Get Started',
                              onPressed: () =>
                                  Navigator.pushNamed(context, AppRoutes.auth),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'SUSL POWERED',
                              style: TextStyle(
                                color:
                                    theme.textTheme.bodyMedium?.color?.withValues(
                                      alpha: 0.5,
                                    ) ??
                                    AppColors.textSecondary,
                                fontSize: 12,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).padding.bottom > 0
                                  ? 10
                                  : 20,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
