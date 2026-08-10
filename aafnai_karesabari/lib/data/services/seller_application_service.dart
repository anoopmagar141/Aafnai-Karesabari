import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../models/seller_application.dart';
import '../repositories/seller_application_repository.dart';
import '../repositories/user_repository.dart';

final sellerApplicationServiceProvider = Provider<SellerApplicationService>((ref) {
  return SellerApplicationService(
    applicationRepository: ref.watch(sellerApplicationRepositoryProvider),
    userRepository: FirestoreUserRepository(),
  );
});

class SellerApplicationService {
  SellerApplicationService({
    required SellerApplicationRepository applicationRepository,
    required UserRepository userRepository,
  })  : _applicationRepository = applicationRepository,
        _userRepository = userRepository;

  final SellerApplicationRepository _applicationRepository;
  final UserRepository _userRepository;

  Future<SellerApplication> submitApplication({
    required String applicantId,
    required String businessName,
    required String businessDescription,
    required String businessAddress,
  }) async {
    if (businessName.trim().isEmpty ||
        businessDescription.trim().isEmpty ||
        businessAddress.trim().isEmpty) {
      throw const AppException('Please fill in all required fields.');
    }

    final application = SellerApplication(
      id: 'application-${DateTime.now().millisecondsSinceEpoch}',
      applicantId: applicantId,
      status: SellerApplicationStatus.pending,
      businessName: businessName.trim(),
      businessDescription: businessDescription.trim(),
      businessAddress: businessAddress.trim(),
      submittedAt: DateTime.now(),
    );

    final created = await _applicationRepository.createApplication(application);
    await _userRepository.updateSellerStatus(applicantId, 'pending');
    return created;
  }

  Future<void> reviewApplication({
    required SellerApplication application,
    required SellerApplicationStatus status,
    required String adminId,
    String? rejectionReason,
  }) async {
    await _applicationRepository.updateApplicationStatus(
      application.id,
      status,
      adminId,
      rejectionReason: rejectionReason,
    );
    await _userRepository.updateSellerStatus(application.applicantId, status.name);
  }
}
