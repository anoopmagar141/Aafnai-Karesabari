import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/seller_application.dart';
import '../../../data/repositories/seller_application_repository.dart';
import '../../../data/services/seller_application_service.dart';
import '../../onboarding/onboarding_controller.dart';

class SellerApplicationsScreen extends ConsumerWidget {
  const SellerApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(sellerApplicationRepositoryProvider);
    final service = ref.watch(sellerApplicationServiceProvider);
    final onboarding = ref.watch(authStateProvider);
    final adminId = onboarding.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Applications'),
      ),
      body: StreamBuilder<List<SellerApplication>>(
        stream: repo.getPendingApplicationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final applications = snapshot.data ?? [];
          if (applications.isEmpty) {
            return const Center(child: Text('No pending applications'));
          }
          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(app.businessName),
                  subtitle: Text('Applicant ID: ${app.applicantId}\nSubmitted: ${app.submittedAt.toLocal()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Approve',
                        onPressed: () async {
                          await service.reviewApplication(
                            application: app,
                            status: SellerApplicationStatus.approved,
                            adminId: adminId,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () async {
                          // Reject without a reason (could be extended to prompt)
                          await service.reviewApplication(
                            application: app,
                            status: SellerApplicationStatus.rejected,
                            adminId: adminId,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
