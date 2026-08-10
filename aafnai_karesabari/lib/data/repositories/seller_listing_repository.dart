import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller_listing.dart';

class SellerListingRepository {
  final CollectionReference<Map<String, dynamic>> _listingsCollection =
      FirebaseFirestore.instance.collection('sellerListings');

  // Create a new listing
  Future<void> create(SellerListing listing) async {
    final docRef = _listingsCollection.doc();
    final data = listing.copyWith(id: docRef.id).toFirestore();
    await docRef.set(data);
  }

  // Read a single listing by id
  Future<SellerListing?> getById(String id) async {
    final doc = await _listingsCollection.doc(id).get();
    if (!doc.exists) return null;
    return SellerListing.fromFirestore(doc);
  }

  // Stream all listings for a particular seller
  Stream<List<SellerListing>> streamBySeller(String sellerId) {
    return _listingsCollection
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SellerListing.fromFirestore(doc))
            .toList());
  }

  // Update an existing listing (full replace)
  Future<void> update(SellerListing listing) async {
    final docRef = _listingsCollection.doc(listing.id);
    await docRef.update(listing.toFirestore());
  }

  // Delete a listing
  Future<void> delete(String id) async {
    await _listingsCollection.doc(id).delete();
  }
}
