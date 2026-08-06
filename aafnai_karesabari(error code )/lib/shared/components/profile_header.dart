import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
class ProfileHeader extends StatelessWidget { const ProfileHeader({super.key, required this.name, required this.role}); final String name, role; @override Widget build(BuildContext context) => Column(children: [const CircleAvatar(radius: 42, backgroundColor: AppColors.softGreen, child: Icon(Icons.person, color: AppColors.primary, size: 48)), const SizedBox(height: 8), Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), Chip(label: Text(role))]); }
