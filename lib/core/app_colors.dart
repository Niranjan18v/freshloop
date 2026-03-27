import 'package:flutter/material.dart';

/// Central branding and color scheme for the FreshLoop ecosystem.
/// Inspired by Notion and Apple Health (Minimalism + Soft Gradients).
class AppColors {
  // Primary branding (Fresh Green)
  static const primary = Color(0xFF10B981); // Emerald Green
  static const primaryLight = Color(0xFFD1FAE5);
  
  // Secondary / Accents (Soft Blue / Sky)
  static const secondary = Color(0xFF3B82F6); // Royal Blue
  static const secondaryLight = Color(0xFFDBEAFE);
  
  // Status Colors (Traffic Light System)
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B); // Amber
  static const error = Color(0xFFEF4444);   // Rose/Red
  
  // Neutrals / Backgrounds
  static const background = Color(0xFFF9FAFB);
  static const card = Colors.white;
  static const border = Color(0xFFE5E7EB);
  
  // Typography
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
}

/// Centralized Text Styles for consistent typography.
class AppTextStyles {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static const subtitle = TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500);
  static const body = TextStyle(fontSize: 14, color: AppColors.textPrimary);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted);
}