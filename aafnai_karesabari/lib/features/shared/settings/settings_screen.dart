import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/typography.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/secure_token_store.dart';
import '../../../features/onboarding/onboarding_controller.dart';
import '../../../routing/app_router.dart';
import '../../../shared/components/confirmation_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = FirebaseAuthService();
  final SecureTokenStore _tokenStore = SecureTokenStore();
  final UserRepository _userRepo = FirestoreUserRepository();
  bool _signingOut = false;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (_currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not signed in')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Scroll down to settings or open settings modal
            },
          )
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: _userRepo.stream(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Failed to load profile.'));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 16),
              _buildAccountInfoCard(user),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildSellerSection(user),
              if (user.socialLinks != null && user.socialLinks!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSocialLinks(user),
              ],
              const SizedBox(height: 16),
              _buildSettingsSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    final joinDate = DateFormat('MMMM yyyy').format(user.createdAt);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? 'Unknown User' : user.name,
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildBadge('Buyer', Colors.blue),
                    if (user.sellerVerified)
                      _buildBadge('Verified Seller', Colors.green),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Joined $joinDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile coming soon')),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.shade700,
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(AppUser user) {
    return _buildSectionCard(
      title: 'Account Information',
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Full Name', user.name),
          _buildInfoRow(Icons.phone_outlined, 'Phone Number', user.phone),
          _buildInfoRow(Icons.email_outlined, 'Email', user.email),
          _buildInfoRow(Icons.location_city_outlined, 'District', user.district),
          _buildInfoRow(Icons.map_outlined, 'Province', user.province),
          _buildInfoRow(
            Icons.language_outlined,
            'Preferred Language',
            user.language == AppLanguage.en ? 'English' : 'Nepali',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value, {bool showDivider = true}) {
    final displayValue = (value == null || value.isEmpty) ? 'Not Added' : value;
    final isNotAdded = displayValue == 'Not Added';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const Spacer(),
              Text(
                displayValue,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isNotAdded ? Colors.grey.shade400 : Colors.black87,
                  fontStyle: isNotAdded ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildQuickActions() {
    return _buildSectionCard(
      title: 'Quick Actions',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildActionItem(Icons.inventory_2_outlined, 'My Orders', () {
            context.go('/consumer/orders');
          }),
          _buildActionItem(Icons.favorite_outline, 'Wishlist', _showComingSoon),
          _buildActionItem(Icons.shopping_cart_outlined, 'Shopping Cart', () {
            context.go(AppRoutes.cart);
          }),
          _buildActionItem(Icons.location_on_outlined, 'Saved Addresses', _showComingSoon),
          _buildActionItem(Icons.notifications_outlined, 'Notifications', () {
            context.go(AppRoutes.notifications);
          }),
          _buildActionItem(Icons.help_outline, 'Support Center', _showComingSoon),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection(AppUser user) {
    if (user.sellerVerified) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FilledButton.icon(
          onPressed: () {
             context.go(AppRoutes.farmerHome);
          },
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Seller Dashboard'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (user.isSeller && !user.sellerVerified) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Application Under Review',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: _showComingSoon, // Navigate to seller application screen once implemented
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withBlue(200),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Become a Seller',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sell your products directly to customers.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _showComingSoon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Apply Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLinks(AppUser user) {
    return _buildSectionCard(
      title: 'Social Links',
      child: Column(
        children: user.socialLinks!.entries.map((entry) {
          IconData icon;
          switch (entry.key.toLowerCase()) {
            case 'facebook':
              icon = Icons.facebook;
              break;
            case 'instagram':
              icon = Icons.camera_alt_outlined; // placeholder for IG
              break;
            case 'tiktok':
              icon = Icons.music_note_outlined; // placeholder for TikTok
              break;
            case 'website':
              icon = Icons.language;
              break;
            default:
              icon = Icons.link;
          }
          return ListTile(
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(entry.key.toUpperCase()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchURL(entry.value),
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return _buildSectionCard(
      title: 'Settings',
      child: Column(
        children: [
          _buildSettingsTile(Icons.language, 'Language', subtitle: 'Change language during a future update'),
          _buildSettingsTile(Icons.privacy_tip_outlined, 'Privacy', onTap: _showComingSoon),
          _buildSettingsTile(Icons.security_outlined, 'Security', onTap: _showComingSoon),
          _buildSettingsTile(Icons.lock_outline, 'Change Password', onTap: _showComingSoon),
          _buildSettingsTile(Icons.notifications_outlined, 'Notification Settings', onTap: _showComingSoon),
          _buildSettingsTile(Icons.help_outline, 'Help & Support', onTap: _showComingSoon),
          _buildSettingsTile(Icons.info_outline, 'About', onTap: _showComingSoon),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(_signingOut ? 'Signing out...' : 'Log out',
                style: const TextStyle(color: Colors.red)),
            enabled: !_signingOut,
            onTap: _confirmLogout,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(7),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feature coming soon!')),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: 'Log out?',
        message: 'You will need to sign in again to access your account.',
        destructive: true,
        onConfirm: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (confirmed != true) return;
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      await _tokenStore.clearSessionToken();
      onboardingController.reset();
      // Router automatically redirects based on authStateChanges
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }
}
