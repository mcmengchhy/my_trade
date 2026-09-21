import 'package:flutter/material.dart';

/// Categorical palette hues, reused here so a name-derived avatar color
/// always comes from the same validated set as the rest of the app.
const _avatarHues = [
  Color(0xFF2A78D6),
  Color(0xFFEB6834),
  Color(0xFF1BAF7A),
  Color(0xFFE87BA4),
  Color(0xFF4A3AA7),
];

Color colorForName(String name) {
  if (name.isEmpty) return _avatarHues.first;
  final hash = name.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return _avatarHues[hash % _avatarHues.length];
}

String initialsForName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = colorForName(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Text(
        initialsForName(name),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
