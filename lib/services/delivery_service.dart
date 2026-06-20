import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/delivery/models/delivery_model.dart';

class DeliveryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _deliveriesCollection = _firestore.collection('deliveries');

  static Future<String> createDelivery({
    required String userId,
    required String itemName,
    required String fullName,
    required String phoneNumber,
    required String address,
    String? tradeId,
  }) async {
    final docRef = _deliveriesCollection.doc();
    final now = DateTime.now();
    final delivery = DeliveryModel(
      id: docRef.id,
      userId: userId,
      itemName: itemName,
      fullName: fullName,
      phoneNumber: phoneNumber,
      address: address,
      status: DeliveryStatus.pending,
      tradeId: tradeId,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(delivery.toFirestore());
    return docRef.id;
  }

  static Stream<List<DeliveryModel>> streamUserDeliveries(String userId) {
    return _deliveriesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DeliveryModel.fromFirestore(doc)).toList());
  }

  static Stream<DeliveryModel?> streamDelivery(String orderId) {
    return _deliveriesCollection.doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return DeliveryModel.fromFirestore(doc);
      }
      return null;
    });
  }

  static Stream<List<DeliveryModel>> streamAgentDeliveries() {
    return _deliveriesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DeliveryModel.fromFirestore(doc)).toList());
  }

  static Future<void> updateDeliveryStatus(String orderId, DeliveryStatus status, String agentId) async {
    await _deliveriesCollection.doc(orderId).update({
      'status': status.name,
      'agentId': agentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns the delivery document created by the OTHER participant for the
  /// given trade — not the current user's own delivery.
  ///
  /// Each user tracks the shipment that is coming **to them**, which is the
  /// delivery set up by the other side of the trade.
  ///
  /// Implementation note: querying on both 'tradeId' AND 'userId' together
  /// requires a Composite Index in Firestore. To avoid that requirement we
  /// query by tradeId only (single-field index, no extra setup) and filter
  /// in-memory. A trade has at most 2 deliveries so this is negligible.
  static Future<String?> getDeliveryIdByTradeAndUser(String tradeId, String userId) async {
    final query = await _deliveriesCollection
        .where('tradeId', isEqualTo: tradeId)
        .get();

    // Return the delivery that was created by the OTHER participant.
    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != userId) {
        return doc.id;
      }
    }

    // Fallback: if only one delivery exists and it belongs to the current user
    // (the other participant hasn't submitted theirs yet), return null so the
    // UI shows "Provide Delivery Details" for the other side rather than
    // accidentally tracking the wrong shipment.
    return null;
  }
}
