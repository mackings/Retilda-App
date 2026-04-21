import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:retilda/Views/Widgets/components.dart';
import 'package:retilda/Views/Widgets/widgets.dart';
import 'package:sizer/sizer.dart';

class CarouselPageView extends StatefulWidget {
  @override
  _CarouselPageViewState createState() => _CarouselPageViewState();
}

class _CarouselPageViewState extends State<CarouselPageView> {
  late final PageController _controller;
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  final List<_Slide> _slides = const [
    _Slide(
      asset: "assets/dr1.png",
      title: "Shop smarter",
      subtitle: "Split payments with flexible options.",
    ),
    _Slide(
      asset: "assets/dr2.png",
      title: "Fast delivery",
      subtitle: "Express shipping on top electronics & lifestyle.",
    ),
    _Slide(
      asset: "assets/dr3.png",
      title: "Secure checkout",
      subtitle: "Encrypted payments and instant notifications.",
    ),
    _Slide(
      asset: "assets/dr4.png",
      title: "Earn rewards",
      subtitle: "Cashback on every checkout, no hidden fees.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final nextPage = (_currentIndex + 1) % _slides.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double height =
        26.h; // cap carousel height to avoid overflow on small screens

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final bool isActive = index == _currentIndex;
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 280),
                    padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 4 : 10,
                        vertical: isActive ? 0 : 6),
                    child: AnimatedScale(
                      scale: isActive ? 1 : 0.96,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                slide.asset,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.62),
                                      Colors.black.withOpacity(0.08),
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(10),
                                        border:
                                            Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.shield_rounded,
                                              color: Colors.white, size: 14.sp),
                                          const SizedBox(width: 6),
                                          CustomText(
                                            "Secure",
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    CustomText(
                                      slide.title,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 4),
                                    CustomText(
                                      slide.subtitle,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: DotsIndicator(
              dotsCount: _slides.length,
              position: _currentIndex.toDouble(),
              decorator: DotsDecorator(
                size: const Size(8.0, 8.0),
                activeSize: const Size(24.0, 8.0),
                color: Colors.grey.shade400,
                activeColor: RButtoncolor,
                spacing: const EdgeInsets.all(5.0),
                activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String asset;
  final String title;
  final String subtitle;

  const _Slide({
    required this.asset,
    required this.title,
    required this.subtitle,
  });
}
