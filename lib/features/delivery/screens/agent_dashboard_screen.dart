import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/delivery_service.dart';
import '../models/delivery_model.dart';
import '../../authentication/models/user_model.dart';

class AgentDashboardScreen extends StatelessWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Dashboard'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<DeliveryModel>>(
        stream: DeliveryService.streamAgentDeliveries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final deliveries = snapshot.data ?? [];

          if (deliveries.isEmpty) {
            return const Center(child: Text('No active deliveries found.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return _DeliveryAgentCard(delivery: delivery);
            },
          );
        },
      ),
    );
  }
}

class _DeliveryAgentCard extends StatelessWidget {
  final DeliveryModel delivery;

  const _DeliveryAgentCard({required this.delivery});

  void _updateStatus(BuildContext context, DeliveryStatus newStatus) async {
    final agentId = UserModel.currentUser?.id;
    if (agentId == null) return;

    try {
      await DeliveryService.updateDeliveryStatus(delivery.id, newStatus, agentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to ${newStatus.displayName}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAgentId = UserModel.currentUser?.id;
    final isAssignedToMe = delivery.agentId == currentAgentId;
    final isUnassigned = delivery.agentId == null;

    return Card(
      elevation: 2,
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
                Expanded(
                  child: Text(
                    'Order: ${delivery.id}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(context, delivery.status),
              ],
            ),
            SizedBox(height: 8.h),
            Text('Item: ${delivery.itemName}'),
            Text('Created: ${delivery.createdAt.toLocal().toString().split('.')[0]}'),
            SizedBox(height: 12.h),
            const Divider(),
            SizedBox(height: 4.h),
            Text('Customer Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16.w, color: Colors.grey),
                SizedBox(width: 8.w),
                Expanded(child: Text(delivery.fullName)),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16.w, color: Colors.grey),
                SizedBox(width: 8.w),
                Expanded(child: Text(delivery.phoneNumber)),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 16.w, color: Colors.grey),
                SizedBox(width: 8.w),
                Expanded(child: Text(delivery.address, maxLines: 3)),
              ],
            ),
            SizedBox(height: 8.h),
            const Divider(),
            SizedBox(height: 12.h),
            if (isUnassigned || isAssignedToMe)
              _buildActionButtons(context)
            else
              const Text(
                'Assigned to another agent',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, DeliveryStatus status) {
    Color color;
    switch (status) {
      case DeliveryStatus.pending:
        color = Colors.orange;
        break;
      case DeliveryStatus.picked_up:
        color = Colors.blue;
        break;
      case DeliveryStatus.in_transit:
        color = Colors.indigo;
        break;
      case DeliveryStatus.out_for_delivery:
        color = Colors.purple;
        break;
      case DeliveryStatus.delivered:
        color = Colors.green;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.sp),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: DeliveryStatus.values.map((status) {
        final isCurrent = delivery.status == status;
        // Don't allow going backwards in the typical flow, or just let them select anything?
        // For simplicity, let them select anything, but highlight the current one
        return ChoiceChip(
          label: Text(status.displayName),
          selected: isCurrent,
          onSelected: (selected) {
            if (selected && !isCurrent) {
              _updateStatus(context, status);
            }
          },
        );
      }).toList(),
    );
  }
}
