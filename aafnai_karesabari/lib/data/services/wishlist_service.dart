import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>(
  (ref) => FirestoreWishlistRepository(),
);

final wishlistNotifierProvider =
    StateNotifierProvider<WishlistNotifier, List<String>>((ref) {
  return WishlistNotifier(ref.watch(wishlistRepositoryProvider));
});

/// Keeps the signed-in buyer's wishlist (a list of listing IDs) in sync
/// with Firestore, automatically re-subscribing when the user signs
/// in/out.
class WishlistNotifier extends StateNotifier<List<String>> {
  WishlistNotifier(this._repository) : super(const []) {
    _subscribeToAuthChanges();
  }

  final WishlistRepository _repository;
  StreamSubscription<List<String>>? _subscription;
  StreamSubscription<User?>? _authSubscription;
  String? _subscribedUid;

  void _subscribeToAuthChanges() {
    // Re-subscribe to the wishlist whenever the signed-in user changes,
    // rather than only once at construction time — this provider can be
    // created before Firebase confirms the current user, and would
    // otherwise never pick up the real wishlist for that session.
    _resubscribe(FirebaseAuth.instance.currentUser?.uid);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _resubscribe(user?.uid);
    });
  }

  void _resubscribe(String? uid) {
    if (uid == _subscribedUid) return;
    _subscribedUid = uid;
    _subscription?.cancel();
    if (uid == null) {
      state = const [];
      return;
    }
    _subscription = _repository.watchWishlist(uid).listen((ids) {
      state = ids;
    });
  }

  Future<void> toggle(String listingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (state.contains(listingId)) {
      await _repository.remove(uid, listingId);
    } else {
      await _repository.add(uid, listingId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
