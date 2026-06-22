import 'package:flutter/material.dart';

/// Leaderboard Color Scheme - Unified for all pages
class LeaderboardColors {
  // Background & Surface
  static const Color backgroundColor = Color(0xFF0D0B1F);
  static const Color surfaceColor = Color(0xFF1A1733);
  static const Color surfaceDark = Color(0xFF15122B);

  // Primary & Accent
  static const Color primary = Color(0xFF6C4AB6);
  static const Color primaryLight = Color(0xFF7D5BC9);
  static const Color primaryDark = Color(0xFF3F2A84);

  // Rank Colors
  static const Color rankGold = Color(0xFFF7A400);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankBronze = Color(0xFFCD7F32);

  // Text Colors
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;
  static const Color textWhite54 = Colors.white54;

  // Status Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  /// Get rank color by ranking position
  static Color getRankColor(int rank) {
    switch (rank) {
      case 1:
        return rankGold;
      case 2:
        return rankSilver;
      case 3:
        return rankBronze;
      default:
        return primary;
    }
  }

  /// Get avatar background color by ranking
  static Color getAvatarColor(int ranking) {
    switch (ranking) {
      case 1:
        return rankGold;
      case 2:
        return rankSilver;
      case 3:
        return rankBronze;
      default:
        return primary;
    }
  }

  /// Get medal emoji by ranking
  static String getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}

/// Leaderboard Typography
class LeaderboardTypography {
  // Headers
  static const headerLarge = TextStyle(
    color: LeaderboardColors.textWhite,
    fontWeight: FontWeight.bold,
    fontSize: 20,
    letterSpacing: 1.5,
  );

  static const headerMedium = TextStyle(
    color: LeaderboardColors.textWhite,
    fontWeight: FontWeight.bold,
    fontSize: 18,
    letterSpacing: 1.5,
  );

  static const headerSmall = TextStyle(
    color: LeaderboardColors.textWhite,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  // Body
  static const bodyLarge = TextStyle(
    color: LeaderboardColors.textWhite,
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  static const bodyMedium = TextStyle(
    color: LeaderboardColors.textWhite,
    fontWeight: FontWeight.w500,
    fontSize: 14,
  );

  static const bodySmall = TextStyle(
    color: LeaderboardColors.textWhite,
    fontWeight: FontWeight.w400,
    fontSize: 12,
  );

  // Labels
  static const labelLarge = TextStyle(
    color: LeaderboardColors.textWhite70,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );

  static const labelMedium = TextStyle(
    color: LeaderboardColors.textWhite70,
    fontWeight: FontWeight.w600,
    fontSize: 12,
  );

  static const labelSmall = TextStyle(
    color: LeaderboardColors.textWhite70,
    fontWeight: FontWeight.w500,
    fontSize: 11,
  );
}

/// Leaderboard Spacing & Dimensions
class LeaderboardDimensions {
  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;

  // Border Radius
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;

  // Icon Sizes
  static const double iconS = 16;
  static const double iconM = 24;
  static const double iconL = 32;

  // Elevation & Shadow
  static const double shadowBlur = 24;
  static const double shadowSpread = 8;
}

/// Shadows for Leaderboard
class LeaderboardShadows {
  static final cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static final elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static final glowShadow = (Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 32,
      spreadRadius: 12,
    ),
  ];
}
