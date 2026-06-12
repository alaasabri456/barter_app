// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/admin/models/report_model.dart';
import '../../features/authentication/models/user_model.dart';
import '../../features/notifications/models/notification_model.dart';
import '../services/notification_service.dart';

/// Repository responsible for report-related data operations.
class ReportRepository {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  ReportRepository({
    FirebaseFirestore? firestore,
    required NotificationService notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService;

  Future<void> submitReport(ReportModel report) async {
    try {
      await _firestore
          .collection('Reports')
          .doc(report.id)
          .set(report.toJson());
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  Future<List<ReportModel>> getAllReports() async {
    try {
      final snapshot = await _firestore
          .collection('Reports')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReportModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports: $e');
    }
  }

  Stream<List<ReportModel>> streamAllReports() {
    return _firestore
        .collection('Reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                return ReportModel.fromJson(doc.data());
              } catch (e) {
                print('Error parsing report: $e');
                return null;
              }
            })
            .whereType<ReportModel>()
            .toList());
  }

  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? adminNote,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'reviewedAt': Timestamp.now(),
      };
      if (adminNote != null) {
        updates['adminNote'] = adminNote;
      }
      await _firestore.collection('Reports').doc(reportId).update(updates);
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  Future<void> notifyAdminsOfReport(ReportModel report) async {
    try {
      final usersSnapshot = await _firestore
          .collection("Users")
          .withConverter<UserModel>(
            fromFirestore: (snapshot, _) =>
                UserModel.fromJson(snapshot.data()!),
            toFirestore: (user, _) => user.toJson(),
          )
          .get();

      final admins = usersSnapshot.docs
          .map((doc) => doc.data())
          .where((user) => user.role == UserRole.admin)
          .toList();

      final reporterName = UserModel.currentUser?.name ?? 'Someone';

      for (final admin in admins) {
        await _notificationService.sendLocalizedNotification(
          recipientId: admin.id,
          titleKey: 'newReportTitle',
          bodyKey: 'newReportBody',
          type: NotificationType.system,
          bodyArgs: {
            'reporter': reporterName,
            'product': report.reportedProductTitle,
            'reason': report.reason.name,
          },
          data: {
            'type': 'report',
            'reportId': report.id,
            'productId': report.reportedProductId,
          },
        );
      }
    } catch (e) {
      print('Failed to notify admins of report: $e');
    }
  }
}
