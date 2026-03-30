import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  spam,
  inappropriateContent,
  scamFraud,
  counterfeit,
  other;

  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.scamFraud:
        return 'Scam / Fraud';
      case ReportReason.counterfeit:
        return 'Counterfeit Product';
      case ReportReason.other:
        return 'Other';
    }
  }
}

enum ReportStatus {
  pending,
  reviewed,
  actioned,
  dismissed;

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.reviewed:
        return 'Reviewed';
      case ReportStatus.actioned:
        return 'Actioned';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }
}

class ReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String reportedProductId;
  final String reportedProductTitle;
  final String reportedProductOwnerId;
  final ReportReason reason;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? adminNote;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reportedProductId,
    required this.reportedProductTitle,
    required this.reportedProductOwnerId,
    required this.reason,
    this.description = '',
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.adminNote,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      reporterId: json['reporterId'] ?? '',
      reporterName: json['reporterName'] ?? '',
      reportedProductId: json['reportedProductId'] ?? '',
      reportedProductTitle: json['reportedProductTitle'] ?? '',
      reportedProductOwnerId: json['reportedProductOwnerId'] ?? '',
      reason: ReportReason.values.firstWhere(
        (r) => r.name == (json['reason'] ?? 'other'),
        orElse: () => ReportReason.other,
      ),
      description: json['description'] ?? '',
      status: ReportStatus.values.firstWhere(
        (s) => s.name == (json['status'] ?? 'pending'),
        orElse: () => ReportStatus.pending,
      ),
      createdAt: _parseDateTime(json['createdAt']),
      reviewedAt: json['reviewedAt'] != null
          ? _parseDateTime(json['reviewedAt'])
          : null,
      adminNote: json['adminNote'],
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    try {
      return (value as dynamic).toDate();
    } catch (_) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reportedProductId': reportedProductId,
        'reportedProductTitle': reportedProductTitle,
        'reportedProductOwnerId': reportedProductOwnerId,
        'reason': reason.name,
        'description': description,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'adminNote': adminNote,
      };
}
