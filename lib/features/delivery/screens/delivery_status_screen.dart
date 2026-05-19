import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../services/delivery_service.dart';
import '../models/delivery_model.dart';

class DeliveryStatusScreen extends StatelessWidget {
  final String orderId;

  const DeliveryStatusScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Tracker'),
        centerTitle: true,
      ),
      body: StreamBuilder<DeliveryModel?>(
        stream: DeliveryService.streamDelivery(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final delivery = snapshot.data;

          if (delivery == null) {
            return const Center(child: Text('Delivery not found.'));
          }

          return Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Item: ${delivery.itemName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Order ID: ${delivery.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                _buildTrackingTimeline(context, delivery.status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackingTimeline(BuildContext context, DeliveryStatus currentStatus) {
    final statuses = DeliveryStatus.values;
    final currentIndex = statuses.indexOf(currentStatus);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Theme.of(context).primaryColor : Colors.grey.shade300,
                  ),
                  child: isCompleted
                      ? Icon(Icons.check, size: 16.w, color: Colors.white)
                      : null,
                ),
                if (index < statuses.length - 1)
                  Container(
                    width: 2.w,
                    height: 40.h,
                    color: isCompleted ? Theme.of(context).primaryColor : Colors.grey.shade300,
                  ),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text(
                  status.displayName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
