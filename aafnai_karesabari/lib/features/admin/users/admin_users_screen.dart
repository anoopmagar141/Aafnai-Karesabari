import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../onboarding/onboarding_controller.dart';

/// Admin user directory: search every platform user and grant/revoke
/// admin access or seller privileges.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final UserRepository _userRepo = FirestoreUserRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _userRepo.list();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = _userRepo.list());
  }

  List<AppUser> _filter(List<AppUser> users) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return users;
    return users
        .where((u) =>
            u.name.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.phone.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _toggleAdmin(AppUser user, String selfUid) async {
    if (user.id == selfUid && user.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't revoke your own admin access.")),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isAdmin ? 'Revoke admin access?' : 'Grant admin access?'),
        content: Text(
          user.isAdmin
              ? '${user.name} will lose admin privileges.'
              : '${user.name} will be able to manage the entire platform.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _userRepo.update(user.copyWith(isAdmin: !user.isAdmin));
    if (mounted) _refresh();
  }

  Future<void> _revokeSeller(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke seller access?'),
        content: Text('${user.name} will no longer be able to list or sell products.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _userRepo.updateSellerStatus(user.id, 'none');
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final selfUid = ref.watch(authStateProvider).uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load users: ${snapshot.error}'));
                }
                final users = _filter(snapshot.data ?? const <AppUser>[]);
                if (users.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _UserTile(
                        user: user,
                        onToggleAdmin: () => _toggleAdmin(user, selfUid),
                        onRevokeSeller: () => _revokeSeller(user),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onToggleAdmin,
    required this.onRevokeSeller,
  });

  final AppUser user;
  final VoidCallback onToggleAdmin;
  final VoidCallback onRevokeSeller;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha(30),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name.isEmpty ? 'Unnamed user' : user.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(user.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (user.isAdmin) _badge('Admin', Colors.purple),
                      _badge(
                        switch (user.sellerStatus) {
                          'approved' => 'Approved seller',
                          'pending' => 'Seller pending',
                          'rejected' => 'Seller rejected',
                          _ => 'Buyer',
                        },
                        switch (user.sellerStatus) {
                          'approved' => AppColors.primary,
                          'pending' => Colors.orange,
                          'rejected' => Colors.red,
                          _ => Colors.grey,
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'admin') onToggleAdmin();
                if (value == 'revoke_seller') onRevokeSeller();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'admin',
                  child: Text(user.isAdmin ? 'Revoke admin access' : 'Grant admin access'),
                ),
                if (user.sellerStatus == 'approved')
                  const PopupMenuItem(
                    value: 'revoke_seller',
                    child: Text('Revoke seller access'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      );
}
