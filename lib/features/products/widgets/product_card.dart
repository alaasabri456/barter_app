import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProductCard extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final String condition;
  final String status; // 'available', 'traded', 'unavailable'
  final int viewCount;
  final int interestedCount;
  final DateTime createdAt;
  final String? imageUrl;
  final String? location;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
    this.imageUrl,
    this.location,
    this.isFavorite = false,
    this.onFavoriteToggle,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${date.day} ${_getMonth(date.month)}';
    } else {
      return '${date.day} ${_getMonth(date.month)}';
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                Container(
                  height: 200.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey[200],
                    image: widget.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.imageUrl == null
                      ? Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48.w,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                ),
                // Heart Icon
                if (widget.onFavoriteToggle != null)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: GestureDetector(
                      onTap: widget.onFavoriteToggle,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: widget.isFavorite
                              ? Colors.red
                              : Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.white,
                          size: 20.w,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8.h),

            // Tags Row (Condition & Rating)
            Row(
              children: [
                _buildTag(
                  _formatCondition(widget.condition),
                  color: _getConditionColor(widget.condition),
                ),
                SizedBox(width: 8.w),
                _buildTag(
                  _getConditionRating(widget.condition),
                  color: _getConditionColor(widget.condition),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Footer (Location & Date)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.location ?? 'No location',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDate(widget.createdAt),
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),

            // Action buttons (only show if callbacks provided and for available products)
            if (widget.status.toLowerCase() == 'available' &&
                widget.onEdit != null &&
                widget.onDelete != null) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onEdit,
                      icon: Icon(Icons.edit_outlined, size: 16.w),
                      label: Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onDelete,
                      icon: Icon(Icons.delete_outline, size: 16.w),
                      label: Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {Color? color}) {
    if (text.isEmpty) return SizedBox.shrink();

    final tagColor = color ?? Colors.grey[100]!;
    final textColor = color != null
        ? tagColor.withOpacity(1.0)
        : Colors.black87;
    final backgroundColor = color != null
        ? tagColor.withOpacity(0.1)
        : Colors.grey[100];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'new_item':
        return 'New';
      case 'like_new':
        return 'Like New';
      default:
        // Capitalize first letter if it's a simple word
        if (condition.isNotEmpty && !condition.contains('_')) {
          return condition[0].toUpperCase() + condition.substring(1);
        }
        return condition;
    }
  }

  String _getConditionRating(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
      case 'new_item':
        return '10/10';
      case 'like new':
      case 'like_new':
        return '9/10';
      case 'good':
        return '7/10';
      case 'fair':
        return '5/10';
      case 'poor':
        return '3/10';
      default:
        return '';
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'new':
      case 'new_item':
        return Colors.green;
      case 'like new':
      case 'like_new':
        return Colors.teal;
      case 'good':
        return Colors.amber[700]!;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
