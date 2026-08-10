import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'firestore_repository.dart';

abstract class UserRepository {
  Future<AppUser> create(AppUser user);
  Future<void> update(AppUser user);
  Future<void> delete(String userId);
  Future<AppUser?> getById(String userId);
  Stream<AppUser?> stream(String userId);
  Future<List<AppUser>> list({int? limit});
  Future<AppUser?> findByPhone(String phone);
  Future<void> updateActiveRole(String uid, String role);
  Future<void> updateSellerStatus(String uid, String status);
}

extension UserRepositoryLegacy on UserRepository {
  Future<AppUser?> read(String userId) => getById(userId);

  Future<void> save(AppUser user) => update(user);
}

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _users = (firestore ?? FirebaseFirestore.instance).collection('users');

  final CollectionReference<Map<String, dynamic>> _users;

  @override
  Future<AppUser> create(AppUser user) => runFirestore(() async {
    await _users.doc(user.id).set(user.toFirestore());
    return user;
  }, message: 'Unable to create user profile.');

  @override
  Future<void> update(AppUser user) => runFirestore(() async {
    await _users.doc(user.id).update(user.toFirestore());
  }, message: 'Unable to update user profile.');

  @override
  Future<void> updateActiveRole(String uid, String role) => runFirestore(() async {
    await _users.doc(uid).update({'activeRole': role});
  }, message: 'Unable to update active role.');

  @override
  Future<void> updateSellerStatus(String uid, String status) => runFirestore(() async {
    await _users.doc(uid).update({'sellerStatus': status});
  }, message: 'Unable to update seller status.');

  @override
  Future<void> delete(String userId) => runFirestore(
        () => _users.doc(userId).delete(),
        message: 'Unable to delete user profile.',
      );

  @override
  Future<AppUser?> getById(String userId) => runFirestore(() async {
    final snapshot = await _users.doc(userId).get();
    if (!snapshot.exists) return null;
    return AppUser.fromFirestore(snapshot);
  }, message: 'Unable to load user profile.');

  @override
  Stream<AppUser?> stream(String userId) {
    return mapDocumentStream(_users.doc(userId), AppUser.fromFirestore);
  }

  @override
  Future<List<AppUser>> list({int? limit}) => runFirestore(() async {
        Query<Map<String, dynamic>> query =
            _users.orderBy('created_at', descending: true);
        if (limit != null) {
          query = query.limit(limit);
        }
        final snapshot = await query.get();
        return mapQuerySnapshot(snapshot, AppUser.fromFirestore);
      }, message: 'Unable to load users.');

  @override
  Future<AppUser?> findByPhone(String phone) => runFirestore(() async {
        final result =
            await _users.where('phone', isEqualTo: phone).limit(1).get();
        if (result.docs.isEmpty) return null;
        return AppUser.fromFirestore(result.docs.first);
      }, message: 'Unable to find user by phone.');
}

class LocalUserRepository implements UserRepository {
  final Map<String, AppUser> _users = {};

  @override
  Future<AppUser> create(AppUser user) async {
    _users[user.id] = user;
    return user;
  }

  @override
  Future<void> update(AppUser user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> delete(String userId) async {
    _users.remove(userId);
  }

  @override
  Future<AppUser?> getById(String userId) async => _users[userId];

  @override
  Stream<AppUser?> stream(String userId) async* {
    yield _users[userId];
  }

  @override
  Future<List<AppUser>> list({int? limit}) async {
    final values = _users.values.toList(growable: false);
    if (limit == null) return values;
    return values.take(limit).toList(growable: false);
  }

  @override
  Future<AppUser?> findByPhone(String phone) async {
    for (final user in _users.values) {
      if (user.phone == phone) return user;
    }
    return null;
  }

  @override
  Future<void> updateActiveRole(String uid, String role) async {
    final user = _users[uid];
    if (user != null) {
      _users[uid] = user.copyWith(activeRole: role);
    }
  }

  @override
  Future<void> updateSellerStatus(String uid, String status) async {
    final user = _users[uid];
    if (user != null) {
      _users[uid] = user.copyWith(sellerStatus: status);
    }
  }
}
