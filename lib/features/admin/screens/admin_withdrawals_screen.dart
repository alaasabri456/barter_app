import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../firebase/firebase_service.dart';
import '../../wallet/models/withdrawal_request_model.dart';

class AdminWithdrawalsScreen extends StatelessWidget {
  const AdminWithdrawalsScreen({super.key});

  Future<void> _updateStatus(BuildContext context, WithdrawalRequestModel request, WithdrawalStatus newStatus) async {
    try {
      await FirebaseService.updateWithdrawalStatus(request.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Withdrawals',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<WithdrawalRequestModel>>(
        stream: FirebaseService.getAllWithdrawalRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(child: Text('No withdrawal requests found.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final bankDetails = request.bankDetails;
              
              return Card(
                margin: EdgeInsets.only(bottom: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${request.amount.toStringAsFixed(2)} EGP',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Theme.of(context).primaryColor),
                          ),
                          _buildStatusBadge(request.status),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Text('Seller: ${request.sellerName}', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.h),
                      Text('Bank: ${bankDetails['bankName'] ?? 'N/A'}'),
                      Text('Account Name: ${bankDetails['accountName'] ?? 'N/A'}'),
                      Text('Account Number: ${bankDetails['accountNumber'] ?? 'N/A'}'),
                      SizedBox(height: 8.h),
                      Text(
                        'Requested: ${_formatDate(request.createdAt)}',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                      
                      if (request.status == WithdrawalStatus.pending) ...[
                        SizedBox(height: 16.h),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _updateStatus(context, request, WithdrawalStatus.rejected),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Reject'),
                            ),
                            SizedBox(width: 8.w),
                            ElevatedButton(
                              onPressed: () => _updateStatus(context, request, WithdrawalStatus.approved),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ] else if (request.status == WithdrawalStatus.approved) ...[
                        SizedBox(height: 16.h),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _updateStatus(context, request, WithdrawalStatus.completed),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text('Mark as Completed'),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStatusBadge(WithdrawalStatus status) {
    Color color;
    String text;

    switch (status) {
      case WithdrawalStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case WithdrawalStatus.approved:
        color = Colors.blue;
        text = 'Approved';
        break;
      case WithdrawalStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case WithdrawalStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
