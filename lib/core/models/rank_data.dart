import 'package:flutter/material.dart';

class RankData {
  final String name;
  final String icon;
  final Color color;
  final int minStories;

  RankData({
    required this.name,
    required this.icon,
    required this.color,
    required this.minStories,
  });

  static List<RankData> allRanks = [
    RankData(
      name: "Apprenti Griot",
      icon: "🌱",
      color: Color(0xFF5A5A40),
      minStories: 0,
    ),
    RankData(
      name: "Messager du Village",
      icon: "🕊️",
      color: Color(0xFF8C6239),
      minStories: 3,
    ), // Un oiseau pour le messager
    RankData(
      name: "Gardien du Savoir",
      icon: "🛡️",
      color: Color(0xFF141414),
      minStories: 10,
    ),
    RankData(
      name: "Griot d'Or",
      icon: "👑",
      color: Color(0xFFD4AF37),
      minStories: 50,
    ),
  ];

  static RankData getRank(int storyCount) {
    return allRanks.reversed.firstWhere((r) => storyCount >= r.minStories);
  }
}
