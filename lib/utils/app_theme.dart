import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert' show base64Decode;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:bonvoyage/services/api_client.dart';

class AppTheme {
  // ── Core Palette ──────────────────────────────────────────────
  static const bg = Color(0xFF080816);
  static const surface = Color(0xFF0E0E24);
  static const card = Color(0xFF141432);
  static const cardBorder = Color(0xFF2A2860);
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF8B83FF);
  static const accent = Color(0xFF00D4FF);
  static const accentAlt = Color(0xFF00FFB2);
  static const success = Color(0xFF4ECDC4);
  static const warning = Color(0xFFFF6B9D);
  static const error = Color(0xFFFF4757);
  static const gold = Color(0xFFFFD93D);

  // ── Gradients ─────────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientWarm = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientCool = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF00FFB2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradientDark = LinearGradient(
    colors: [Color(0xFF141432), Color(0xFF0E0E24)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const gradientPurple = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFBB6BD9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text Styles ───────────────────────────────────────────────
  static const headingLg = TextStyle(
    color: Colors.white,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );
  static const headingMd = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const headingSm = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const bodyLg = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const bodyMd = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const bodySm = TextStyle(
    color: Colors.white70,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const caption = TextStyle(
    color: Colors.white54,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
  static const label = TextStyle(
    color: Colors.white60,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // ── Animation Constants ───────────────────────────────────────
  static const animFast = Duration(milliseconds: 200);
  static const animNormal = Duration(milliseconds: 350);
  static const animSlow = Duration(milliseconds: 600);
  static const curveBounce = Curves.easeOutBack;
  static const curveSmooth = Curves.easeInOutCubicEmphasized;

  // ── Decorations ───────────────────────────────────────────────
  static BoxDecoration glassCard({double radius = 20, Color? borderColor}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration gradientCard({
    required LinearGradient gradient,
    double radius = 20,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration solidCard({double radius = 16}) => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder.withValues(alpha: 0.5)),
      );

  // ── Input Decoration ──────────────────────────────────────────
  static InputDecoration input(String label, {IconData? icon}) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white38, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  // ── Button Styles ─────────────────────────────────────────────
  static ButtonStyle gradientButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
      );

  static ButtonStyle outlineButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: const BorderSide(color: accent, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  static Widget imageFromPath(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    int? cacheWidth,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (path.isEmpty) {
      return errorWidget ?? const Center(child: Icon(Icons.image_outlined, color: Colors.white24));
    }

    String finalPath = path;
    if (path.startsWith('/uploads/')) {
      finalPath = '${ApiClient.baseUrl}$path';
    }

    if (finalPath.startsWith('http://') || finalPath.startsWith('https://')) {
      return Image.network(
        finalPath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24)),
      );
    } else if (finalPath.startsWith('data:')) {
      try {
        final commaIdx = finalPath.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = finalPath.substring(commaIdx + 1).replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(base64Str);
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: cacheWidth,
            errorBuilder: (context, error, stackTrace) =>
                errorWidget ?? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24)),
          );
        }
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
      }
      return errorWidget ?? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24));
    } else if (!kIsWeb) {
      final file = File(finalPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: cacheWidth,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24)),
        );
      }
    }
    return errorWidget ?? const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24));
  }

  static ImageProvider? imageProviderFromPath(String path) {
    if (path.isEmpty) return null;
    String finalPath = path;
    if (path.startsWith('/uploads/')) {
      finalPath = '${ApiClient.baseUrl}$path';
    }
    if (finalPath.startsWith('http://') || finalPath.startsWith('https://')) {
      return NetworkImage(finalPath);
    } else if (finalPath.startsWith('data:')) {
      try {
        final commaIdx = finalPath.indexOf(',');
        if (commaIdx != -1) {
          final base64Str = finalPath.substring(commaIdx + 1).replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(base64Str);
          return MemoryImage(bytes);
        }
      } catch (e) {
        debugPrint('Error decoding base64 image provider: $e');
      }
    } else if (!kIsWeb) {
      final file = File(finalPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
  }

  static Widget buildPackageImage(List<dynamic> images, {double size = 70, double radius = 12}) {
    final Widget defaultPlaceholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(child: Icon(Icons.beach_access_rounded, color: const Color(0xFF00D4FF), size: size * 0.43)),
    );

    if (images.isNotEmpty) {
      final path = images.first.imagePath;
      if (path.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: imageFromPath(
            path,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: Container(
              width: size,
              height: size,
              color: Colors.white.withValues(alpha: 0.08),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00D4FF),
                ),
              ),
            ),
            errorWidget: Container(
              width: size,
              height: size,
              color: Colors.white.withValues(alpha: 0.08),
              child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white30, size: 24)),
            ),
          ),
        );
      }
    }
    return defaultPlaceholder;
  }
}

// ── Global Helpers ────────────────────────────────────────────────

void showAppSnackBar(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
        ],
      ),
    ),
  );
}



String formatDate(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

String formatCurrency(double amount) => 'RM ${amount.toStringAsFixed(2)}';

/// Stat card for dashboards
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.gradient = AppTheme.gradientPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.gradientCard(gradient: gradient, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
          const Spacer(),
          Text(value, style: AppTheme.headingMd),
          const SizedBox(height: 4),
          Text(title, style: AppTheme.bodySm.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

/// Empty state placeholder
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.headingSm.copyWith(color: Colors.white38)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: AppTheme.bodySm, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Section header with optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title, style: AppTheme.headingSm),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(color: AppTheme.accent)),
            ),
        ],
      ),
    );
  }
}

/// Star rating widget
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final bool interactive;
  final ValueChanged<int>? onChanged;
  const StarRating({
    super.key,
    required this.rating,
    this.size = 18,
    this.interactive = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        final isFull = rating >= starValue;
        final isHalf = rating >= starValue - 0.5 && rating < starValue;
        return GestureDetector(
          onTap: interactive ? () => onChanged?.call(starValue) : null,
          child: Icon(
            isFull
                ? Icons.star_rounded
                : isHalf
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            color: AppTheme.gold,
            size: size,
          ),
        );
      }),
    );
  }
}

/// Status badge
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color => switch (status.toLowerCase()) {
        'active' || 'confirmed' || 'paid' || 'completed' || 'published' => AppTheme.success,
        'pending' => AppTheme.gold,
        'suspended' || 'cancelled' || 'rejected' || 'deleted' => AppTheme.error,
        'draft' => Colors.white38,
        _ => AppTheme.accent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}
