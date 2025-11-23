// models/onboarding_data.dart
import 'package:flutter/material.dart';

class OnBoardingModel {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnBoardingModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<OnBoardingModel> onboardingPages = [
  OnBoardingModel(
    title: 'Discover Items',
    description: 'Browse through a wide variety of items...',
    icon: Icons.search_outlined,
    color: Colors.blue,
  ),
  OnBoardingModel(
    title: 'List Your Items',
    description: 'Take photos of items you no longer need...',
    icon: Icons.add_circle_outline,
    color: Colors.green,
  ),
  OnBoardingModel(
    title: 'Make Trades',
    description: 'Connect with other users and arrange fair trades...',
    icon: Icons.handshake_outlined,
    color: Colors.orange,
  ),
  OnBoardingModel(
    title: 'Stay Sustainable',
    description: 'Help reduce waste and promote sustainability...',
    icon: Icons.eco_outlined,
    color: Colors.purple,
  ),
];
