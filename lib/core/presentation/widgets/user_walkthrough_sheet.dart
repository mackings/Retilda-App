import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPurchaseWalkthroughSeenKey = 'retilda.walkthrough.purchase.seen';
const String kPurchaseWalkthroughDisabledKey =
    'retilda.walkthrough.purchase.disabled';

Future<bool> shouldAutoShowPurchaseWalkthrough() async {
  final prefs = await SharedPreferences.getInstance();
  final disabled = prefs.getBool(kPurchaseWalkthroughDisabledKey) ?? false;
  final seen = prefs.getBool(kPurchaseWalkthroughSeenKey) ?? false;
  return !disabled && !seen;
}

Future<void> showUserPurchaseWalkthroughSheet(
  BuildContext context, {
  bool showDisableOption = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) {
    return;
  }
  bool disableFutureAutoShow =
      prefs.getBool(kPurchaseWalkthroughDisabledKey) ?? false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 56,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0B3150),
                                Color(0xFF145E8D),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.play_lesson_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'How buying works on Retilda',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Understand product buying, direct debit, and the safer alternatives before you continue.',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  height: 1.55,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _WalkthroughStep(
                          step: '1',
                          title: 'Choose your product and payment plan',
                          body:
                              'Open a product, review the details, then choose whether you want outright payment or an installment plan before continuing to checkout.',
                          icon: Icons.shopping_bag_outlined,
                          accent: AppTheme.ocean,
                        ),
                        const SizedBox(height: 12),
                        const _WalkthroughStep(
                          step: '2',
                          title: 'Pick how you want to pay',
                          body:
                              'Card checkout lets you pay directly with your bank card, either one time or for installment starts. Wallet installment checkout may require a connected bank account for repayment collections.',
                          icon: Icons.account_balance_wallet_outlined,
                          accent: AppTheme.accent,
                        ),
                        const SizedBox(height: 12),
                        const _WalkthroughStep(
                          step: '3',
                          title: 'Know what direct debit means',
                          body:
                              'Direct debit means a connected bank account may be used for scheduled repayment collections after you approve the connection. It is not required for every purchase.',
                          icon: Icons.sync_alt_rounded,
                          accent: Color(0xFF0E7C66),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF8D8B8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'How to avoid direct debit',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'If you do not want direct debit, choose card payment options like One Time Pay or Installment Card and avoid connecting your bank account for automated repayment collections.',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  height: 1.55,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showDisableOption) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: CheckboxListTile(
                              value: disableFutureAutoShow,
                              onChanged: (value) {
                                setState(() {
                                  disableFutureAutoShow = value ?? false;
                                });
                              },
                              title: Text(
                                "Don't show this walkthrough automatically again",
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.ink,
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await prefs.setBool(
                                    kPurchaseWalkthroughSeenKey,
                                    true,
                                  );
                                  await prefs.setBool(
                                    kPurchaseWalkthroughDisabledKey,
                                    disableFutureAutoShow,
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  'Close',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  await prefs.setBool(
                                    kPurchaseWalkthroughSeenKey,
                                    true,
                                  );
                                  await prefs.setBool(
                                    kPurchaseWalkthroughDisabledKey,
                                    disableFutureAutoShow,
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.ink,
                                  minimumSize: const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  'Got it',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _WalkthroughStep extends StatelessWidget {
  const _WalkthroughStep({
    required this.step,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String step;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 19,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
