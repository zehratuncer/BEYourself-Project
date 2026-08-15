import 'dart:async';
import 'package:flutter/material.dart';

import 'package:be_yourself/core/constants/app_strings.dart';
import 'package:be_yourself/core/theme/app_colors.dart';
import 'package:be_yourself/features/onboarding/presentation/widgets/logo_card.dart';
import 'package:be_yourself/shared/widgets/main_shell_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  static bool isShowing = false;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _splashTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WelcomePage.isShowing = true;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // Auto navigate after 2 seconds splash screen
    _splashTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted && WelcomePage.isShowing) {
        _navigateToHome();
      }
    });
  }

  @override
  void dispose() {
    WelcomePage.isShowing = false;
    _splashTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    WelcomePage.isShowing = false;
    _splashTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainShellPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: _navigateToHome,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background soft radial aura glow
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.1),
                    radius: 0.85,
                    colors: [
                      AppColors.auraGlowInner,
                      AppColors.auraGlowOuter,
                    ],
                  ),
                ),
              ),
            ),

            // Central content (Logo, Title, Subtitle)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        const LogoCard(),
                        const SizedBox(height: 36),
                        Text(
                          AppStrings.appName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ) ?? const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.welcomeSubtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.lightTextSecondary,
                          ) ?? const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(flex: 3),

                        // Bottom subtle indicator line
                        Container(
                          width: size.width * 0.45,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.bottomIndicator,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
