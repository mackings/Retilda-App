import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Auth/Signin.dart';
import 'package:retilda/Views/Auth/Signup.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String seenKey = 'retilda_seen_onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingItem> _pages = [
    _OnboardingItem(
      title: 'Shop trusted products built for projects that move fast.',
      description:
          'Retilda helps users discover reliable materials, compare options clearly, and buy with confidence from one streamlined marketplace.',
      label: 'Marketplace',
      accent: Color(0xFF145E8D),
      icon: Icons.storefront_rounded,
      points: [
        'Browse materials and everyday essentials',
        'Review clear pricing before checkout',
        'Keep your orders in one organized place',
      ],
    ),
    _OnboardingItem(
      title: 'Pay smarter with wallet support and flexible transactions.',
      description:
          'From secure payments to purchase tracking, Retilda gives users better control over how money moves inside each order.',
      label: 'Payments',
      accent: Color(0xFFFB9324),
      icon: Icons.account_balance_wallet_rounded,
      points: [
        'Fund purchases with structured payment flows',
        'Track transaction history without guesswork',
        'Reduce friction between checkout and fulfillment',
      ],
    ),
    _OnboardingItem(
      title: 'Stay updated from checkout to delivery.',
      description:
          'Retilda connects ordering, delivery updates, and status visibility so users always know what happens next.',
      label: 'Tracking',
      accent: Color(0xFF0E7C66),
      icon: Icons.local_shipping_rounded,
      points: [
        'Follow delivery progress in real time',
        'See order status changes at a glance',
        'Manage your account from one dashboard',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({required Widget nextPage}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.seenKey, true);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  void _handleNext() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding(nextPage: const Signup());
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final bool isCompact = size.width < 380;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: size.width < 700 ? 20 : size.width * 0.08,
      vertical: 18,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FBFF),
              Color(0xFFF2F6FB),
              Color(0xFFFFFAF4),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: padding,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        color: AppTheme.ink,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Retilda',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: isCompact ? 28 : 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _completeOnboarding(
                        nextPage: const Signup(),
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return _OnboardingPage(
                        item: item,
                        isCompact: isCompact,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ...List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[index].accent
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.ink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _handleNext,
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Create account'
                                : 'Continue',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _completeOnboarding(
                        nextPage: const Signin(),
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.item,
    required this.isCompact,
  });

  final _OnboardingItem item;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double artHeight = size.height * (isCompact ? 0.3 : 0.34);
    final double cardPadding = isCompact ? 18 : 24;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: size.height * 0.66,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: artHeight,
              child: _IllustrationCard(item: item),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.label,
                      style: GoogleFonts.manrope(
                        color: item.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: isCompact ? 28 : 34,
                      height: 1.05,
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.description,
                    style: GoogleFonts.manrope(
                      fontSize: isCompact ? 14 : 15.5,
                      height: 1.55,
                      color: Colors.black.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...item.points.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            height: 22,
                            width: 22,
                            decoration: BoxDecoration(
                              color: item.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: item.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              point,
                              style: GoogleFonts.manrope(
                                fontSize: isCompact ? 13.5 : 14.5,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth =
            (constraints.maxWidth - 52).clamp(220.0, 420.0);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.accent.withValues(alpha: 0.14),
                Colors.white,
                AppTheme.ink.withValues(alpha: 0.06),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -12,
                child: _GlowBubble(
                  size: 120,
                  color: item.accent.withValues(alpha: 0.16),
                ),
              ),
              Positioned(
                bottom: -26,
                left: -16,
                child: _GlowBubble(
                  size: 150,
                  color: AppTheme.ink.withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                top: 26,
                left: 22,
                child: _StatChip(
                  icon: Icons.bolt_rounded,
                  text: item.label,
                  color: item.accent,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 56, 26, 32),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 94,
                              width: 94,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.accent.withValues(alpha: 0.14),
                              ),
                              child: Icon(
                                item.icon,
                                color: item.accent,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _MiniFeatureCard(
                                  icon: Icons.shield_rounded,
                                  title: 'Secure',
                                  color: AppTheme.ink,
                                ),
                                const SizedBox(width: 12),
                                _MiniFeatureCard(
                                  icon: Icons.flash_on_rounded,
                                  title: 'Simple',
                                  color: item.accent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const _ProgressStrip(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppTheme.ink,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E1EA),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFeatureCard extends StatelessWidget {
  const _MiniFeatureCard({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.label,
    required this.accent,
    required this.icon,
    required this.points,
  });

  final String title;
  final String description;
  final String label;
  final Color accent;
  final IconData icon;
  final List<String> points;
}
