import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/custom_dialog.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String description;
  final String category;
  final String condition;
  final String status;
  final int viewCount;
  final int interestedCount;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? imageUrl;

  const ProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.status,
    required this.viewCount,
    required this.interestedCount,
    required this.createdAt,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.imageUrl,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'traded':
        return Colors.orange;
      case 'reserved':
        return Colors.blue;
      case 'unavailable':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showOptionsMenu(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'Product Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 24.h),

            ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit Product'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),

            ListTile(
              leading: Icon(Icons.share_outlined),
              title: Text('Share Product'),
              onTap: () => Navigator.of(context).pop('share'),
            ),

            if (status.toLowerCase() == 'available') ...[
              ListTile(
                leading: Icon(Icons.pause_outlined),
                title: Text('Mark as Unavailable'),
                onTap: () => Navigator.of(context).pop('unavailable'),
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.play_arrow_outlined),
                title: Text('Mark as Available'),
                onTap: () => Navigator.of(context).pop('available'),
              ),
            ],

            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete Product',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );

    if (result != null) {
      switch (result) {
        case 'edit':
          onEdit?.call();
          break;
        case 'share':
        // Handle share
          break;
        case 'available':
        case 'unavailable':
        // Handle status change
          break;
        case 'delete':
          await _showDeleteConfirmation(context);
          break;
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Product',
      message: 'Are you sure you want to delete this product? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Theme.of(context).colorScheme.error,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    IconButton(
                      onPressed: () => _showOptionsMenu(context),
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 32.w,
                        minHeight: 32.h,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Description
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 12.h),

                // Product image placeholder (if imageUrl is provided, you can use NetworkImage)
                if (imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      width: double.infinity,
                      height: 150.h,
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.image,
                        size: 48.w,
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],

                // Status and category chips
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),

                    SizedBox(width: 8.w),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),

                    SizedBox(width: 8.w),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        condition,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Statistics and timestamp row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 16.w,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$viewCount views',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),

                        SizedBox(width: 16.w),

                        Icon(
                          Icons.people_outlined,
                          size: 16.w,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$interestedCount interested',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),

                    Text(
                      _getTimeAgo(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}