import 'package:flutter/material.dart';

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}