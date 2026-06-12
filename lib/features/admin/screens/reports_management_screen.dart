// ignore_for_file: deprecated_member_use

import 'package:barter/features/admin/models/report_model.dart';
import 'package:provider/provider.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportsManagementScreen extends StatefulWidget {
  const ReportsManagementScreen({super.key});

  @override
  State<ReportsManagementScreen> createState() =>
      _ReportsManagementScreenState();
}

class _ReportsManagementScreenState extends State<ReportsManagementScreen> {
  ReportStatus? _selectedStatus;

  List<ReportModel> _filterReportsList(List<ReportModel> reports) {
    if (_selectedStatus == null) {
      return reports;
    } else {
      return reports.where((r) => r.status == _selectedStatus).toList();
    }
  }

  void _setFilter(ReportStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  Future<void> _dismissReport(ReportModel report) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add an optional note for this dismissal:'),
            SizedBox(height: 12.h),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Admin note (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, noteController.text.trim()),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    if (note == null) return;

    try {
      await context.read<AdminViewModel>().updateReportStatus(
        reportId: report.id,
        newStatus: ReportStatus.dismissed,
        adminNote: note.isEmpty ? 'Dismissed by admin' : note,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report dismissed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _removeProduct(ReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Product'),
        content: Text(
          'Are you sure you want to permanently delete the product "${report.reportedProductTitle}"?\n\n'
          'This action CANNOT be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Product'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<AdminViewModel>().deleteProductById(report.reportedProductId);
      await context.read<AdminViewModel>().updateReportStatus(
        reportId: report.id,
        newStatus: ReportStatus.actioned,
        adminNote: 'Action taken: Product deleted',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product removed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _suspendOwner(ReportModel report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Product Owner'),
        content: Text(
          'Are you sure you want to suspend the user who owns "${report.reportedProductTitle}"?\n\n'
          'This will mark all their products as unavailable and reject pending trades.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await context.read<AdminViewModel>().suspendUser(report.reportedProductOwnerId);
      await context.read<AdminViewModel>().updateReportStatus(
        reportId: report.id,
        newStatus: ReportStatus.actioned,
        adminNote: 'Product owner suspended by admin',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User suspended and report resolved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null),
                  SizedBox(width: 8.w),
                  ...ReportStatus.values.map((status) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildFilterChip(status.displayName, status),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: context.read<AdminViewModel>().streamAllReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16.h),
                        Text('Error: ${snapshot.error}'),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final reports = snapshot.data ?? [];
                final filteredReports = _filterReportsList(reports);

                if (filteredReports.isEmpty) {
                  return Center(
                    child: Text(
                      'No reports found',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return _buildReportCard(report, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ReportStatus? status) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _setFilter(selected ? status : null);
      },
    );
  }

  Widget _buildReportCard(ReportModel report, bool isDark) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(report.status).withOpacity(0.15),
          child: Icon(
            _getStatusIcon(report.status),
            color: _getStatusColor(report.status),
            size: 22.sp,
          ),
        ),
        title: Text(
          report.reportedProductTitle,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Row(
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getReasonColor(report.reason).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    report.reason.displayName,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: _getReasonColor(report.reason),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    report.status.displayName,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: _getStatusColor(report.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'By: ${report.reporterName}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Product ID', report.reportedProductId),
                _buildDetailRow('Reporter', report.reporterName),
                _buildDetailRow('Reason', report.reason.displayName),
                if (report.description.isNotEmpty)
                  _buildDetailRow('Description', report.description),
                _buildDetailRow(
                  'Reported on',
                  '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year} at ${report.createdAt.hour}:${report.createdAt.minute.toString().padLeft(2, '0')}',
                ),
                if (report.adminNote != null)
                  _buildDetailRow('Admin Note', report.adminNote!),
                if (report.reviewedAt != null)
                  _buildDetailRow(
                    'Reviewed on',
                    '${report.reviewedAt!.day}/${report.reviewedAt!.month}/${report.reviewedAt!.year}',
                  ),
                SizedBox(height: 16.h),
                if (report.status == ReportStatus.pending) ...[
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _dismissReport(report),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Dismiss'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _removeProduct(report),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Remove Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _suspendOwner(report),
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Suspend Owner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: _getStatusColor(report.status).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(report.status),
                          color: _getStatusColor(report.status),
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'This report has been ${report.status.displayName.toLowerCase()}.',
                            style: TextStyle(
                              color: _getStatusColor(report.status),
                              fontWeight: FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.reviewed:
        return Colors.blue;
      case ReportStatus.actioned:
        return Colors.red;
      case ReportStatus.dismissed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.pending;
      case ReportStatus.reviewed:
        return Icons.visibility;
      case ReportStatus.actioned:
        return Icons.gavel;
      case ReportStatus.dismissed:
        return Icons.check_circle;
    }
  }

  Color _getReasonColor(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return Colors.blue;
      case ReportReason.inappropriateContent:
        return Colors.purple;
      case ReportReason.scamFraud:
        return Colors.red;
      case ReportReason.counterfeit:
        return Colors.orange;
      case ReportReason.other:
        return Colors.grey;
    }
  }
}
