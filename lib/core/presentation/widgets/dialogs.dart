import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/core/theme/app_theme.dart';

enum AppFeedbackTone { info, success, warning, error }

class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.titleColor = Colors.black,
    this.messageColor = Colors.black87,
    this.onClosePressed,
    this.onButtonPressed,
    this.buttonText = 'Continue',
    this.secondaryButtonText,
    this.onSecondaryButtonPressed,
    this.icon,
  });

  final String title;
  final String message;
  final Color titleColor;
  final Color messageColor;
  final VoidCallback? onClosePressed;
  final VoidCallback? onButtonPressed;
  final String buttonText;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryButtonPressed;
  final IconData? icon;

  AppFeedbackTone get _tone {
    if (titleColor == Colors.red || titleColor == Colors.redAccent) {
      return AppFeedbackTone.error;
    }
    if (titleColor == Colors.orange || titleColor == Colors.amber) {
      return AppFeedbackTone.warning;
    }
    if (titleColor == Colors.green || titleColor == Colors.greenAccent) {
      return AppFeedbackTone.success;
    }
    if (title.toLowerCase().contains('success')) {
      return AppFeedbackTone.success;
    }
    if (title.toLowerCase().contains('error') ||
        title.toLowerCase().contains('failed')) {
      return AppFeedbackTone.error;
    }
    return AppFeedbackTone.info;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _toneStyle(_tone);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 40,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 16, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.surface,
                    Colors.white,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: scheme.tint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon ?? scheme.icon,
                      color: scheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 28,
                              height: 1.0,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.tint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              scheme.label,
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        onClosePressed ?? () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F7FB),
                      foregroundColor: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: messageColor == Colors.black87
                          ? Colors.black.withValues(alpha: 0.72)
                          : messageColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (secondaryButtonText != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onSecondaryButtonPressed ??
                                () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              side: BorderSide(color: scheme.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              secondaryButtonText!,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: onButtonPressed ??
                                () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.primary,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onButtonPressed ??
                            () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          buttonText,
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAppAlert<T>({
  required BuildContext context,
  required String title,
  required String message,
  AppFeedbackTone tone = AppFeedbackTone.info,
  String buttonText = 'Continue',
  VoidCallback? onButtonPressed,
  String? secondaryButtonText,
  VoidCallback? onSecondaryButtonPressed,
  bool barrierDismissible = true,
  IconData? icon,
}) {
  final scheme = _toneStyle(tone);

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => CustomAlertDialog(
      title: title,
      message: message,
      titleColor: scheme.primary,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      secondaryButtonText: secondaryButtonText,
      onSecondaryButtonPressed: onSecondaryButtonPressed,
      onClosePressed: () => Navigator.of(context).pop(),
      icon: icon,
    ),
  );
}

Future<T?> showAppNoticeSheet<T>({
  required BuildContext context,
  required String title,
  required String message,
  AppFeedbackTone tone = AppFeedbackTone.info,
  String primaryLabel = 'Continue',
  VoidCallback? onPrimaryPressed,
  String? secondaryLabel,
  VoidCallback? onSecondaryPressed,
  IconData? icon,
  bool isDismissible = true,
}) {
  final scheme = _toneStyle(tone);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ).copyWith(
              bottomLeft: const Radius.circular(30),
              bottomRight: const Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: scheme.tint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon ?? scheme.icon,
                      color: scheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onPrimaryPressed ??
                          () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        primaryLabel,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondaryPressed ??
                            () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: BorderSide(color: scheme.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          secondaryLabel,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppFeedbackTone tone = AppFeedbackTone.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final scheme = _toneStyle(tone);
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: scheme.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(scheme.icon, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

_AppFeedbackStyle _toneStyle(AppFeedbackTone tone) {
  switch (tone) {
    case AppFeedbackTone.success:
      return const _AppFeedbackStyle(
        primary: Color(0xFF0E7C66),
        tint: Color(0xFFE8F7F2),
        surface: Color(0xFFF4FCF9),
        border: Color(0xFFB7E8DA),
        icon: Icons.check_circle_rounded,
        label: 'Success',
      );
    case AppFeedbackTone.warning:
      return const _AppFeedbackStyle(
        primary: Color(0xFFB54708),
        tint: Color(0xFFFFF1E8),
        surface: Color(0xFFFFFAF5),
        border: Color(0xFFF8D8B8),
        icon: Icons.warning_amber_rounded,
        label: 'Attention',
      );
    case AppFeedbackTone.error:
      return const _AppFeedbackStyle(
        primary: Color(0xFFB42318),
        tint: Color(0xFFFFEDEA),
        surface: Color(0xFFFFF6F5),
        border: Color(0xFFF3C9C5),
        icon: Icons.cancel_rounded,
        label: 'Error',
      );
    case AppFeedbackTone.info:
      return const _AppFeedbackStyle(
        primary: AppTheme.ocean,
        tint: Color(0xFFEAF4FB),
        surface: Color(0xFFF6FBFF),
        border: Color(0xFFC7E0F3),
        icon: Icons.info_rounded,
        label: 'Notice',
      );
  }
}

class _AppFeedbackStyle {
  const _AppFeedbackStyle({
    required this.primary,
    required this.tint,
    required this.surface,
    required this.border,
    required this.icon,
    required this.label,
  });

  final Color primary;
  final Color tint;
  final Color surface;
  final Color border;
  final IconData icon;
  final String label;
}
