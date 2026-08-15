import 'package:cloud_firestore/cloud_firestore.dart';

/// A buyer's saved-for-later listings, stored as a `wishlist` subcollection
/// under their own `users/{uid}` document.
abstract class WishlistRepository {
  /// Returns a stream of listing IDs in the user's wishlist.
  Stream<List<String>> watchWishlist(String uid);

  /// Adds a listing to the user's wishlist.
  Future<void> add(String uid, String listingId);

  /// Removes a listing from the user's wishlist.
  Future<void> remove(String uid, String listingId);
}

class FirestoreWishlistRepository implements WishlistRepository {
  FirestoreWishlistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userWishlists(String uid) =>
      _firestore.collection('users').doc(uid).collection('wishlist');

  @override
  Stream<List<String>> watchWishlist(String uid) {
    return _userWishlists(uid).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.id).toList(growable: false));
  }

  @override
  Future<void> add(String uid, String listingId) async {
    await _userWishlists(uid).doc(listingId).set({});
  }

  @override
  Future<void> remove(String uid, String listingId) async {
    await _userWishlists(uid).doc(listingId).delete();
  }
}
