import 'package:flutter/material.dart';

/// Responsive breakpoints untuk dashboard
class DashboardResponsive {
  static const double mobileMaxWidth = 480;
  static const double tabletMinWidth = 481;
  static const double tabletMaxWidth = 900;
  static const double desktopMinWidth = 901;
  
  static const double sidebarWidth = 300;

  /// Get responsive padding berdasarkan screen width
  static EdgeInsets getContentPadding(double width) {
    if (width < mobileMaxWidth) {
      return const EdgeInsets.all(12);
    } else if (width < desktopMinWidth) {
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(20);
  }

  /// Get spacing berdasarkan screen width
  static double getSpacing(double width) {
    if (width < mobileMaxWidth) {
      return 8;
    } else if (width < desktopMinWidth) {
      return 12;
    }
    return 16;
  }

  /// Check apakah harus menampilkan sidebar tetap (desktop mode)
  static bool shouldShowFixedSidebar(double width) => width >= desktopMinWidth;

  /// Get grid columns untuk responsive grid
  static int getGridColumns(double width) {
    if (width < mobileMaxWidth) {
      return 1;
    } else if (width < tabletMaxWidth) {
      return 2;
    }
    return 3;
  }

  /// Get stat card width untuk responsive layout
  static double getStatCardWidth(double width) {
    if (width < mobileMaxWidth) {
      return double.infinity;
    } else if (width < tabletMaxWidth) {
      return (width - 32) / 2 - 6;
    }
    return 260;
  }
}
