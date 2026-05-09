// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../premium/widgets/premium_badge_widget.dart';

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
  final double? imageHeight;
  final String? type; // 'item' or 'service'
  final String? availability; // For services
  final double? distance; // In kilometers
  final String? transactionType; // 'sell' or 'barter'
  final double? price;
  final bool isOwnerPremium;

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
    this.imageHeight,
    this.type,
    this.availability,
    this.distance,
    this.transactionType,
    this.price,
    this.isOwnerPremium = false,
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxHeight = constraints.maxHeight;
            final bool isConstrained =
                maxHeight != double.infinity && maxHeight > 0;

            // For action buttons, we check if they should be visible
            final bool showActions =
                widget.status.toLowerCase() == 'available' &&
                    widget.onEdit != null &&
                    widget.onDelete != null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image Section - use Expanded in a constrained grid, else fixed height
                if (isConstrained)
                  Expanded(child: _buildImageSection(isExpanded: true))
                else
                  _buildImageSection(),

                // Content Section
                _buildContentSection(context),

                // Action buttons Section
                if (showActions) _buildActionsSection(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSection({bool isExpanded = false}) {
    return Stack(
      children: [
        Container(
          height: isExpanded ? double.infinity : (widget.imageHeight ?? 200.h),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
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
        // Premium badge (top-left)
        if (widget.isOwnerPremium)
          Positioned(
            top: 12.h,
            left: 12.w,
            child: const PremiumBadgeWidget.compact(),
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : Colors.grey[600],
                  size: 18.w,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),

          // Type Badge and Condition/Availability Badge
          Wrap(
            spacing: 8.w,
            runSpacing: 4.h,
            children: [
              // Type badge (Item/Service)
              if (widget.type != null)
                _buildTag(
                  widget.type == 'item' ? 'Item' : 'Service',
                  color: widget.type == 'item' ? Colors.blue : Colors.purple,
                ),

              if (widget.type != null) SizedBox(width: 8.w),

              // Condition or Availability badge
              if (widget.type == 'service' && widget.availability != null)
                _buildTag(
                  _formatCondition(widget.availability!),
                  color: Colors.teal,
                )
              else
                _buildTag(
                  _formatCondition(widget.condition),
                  color: _getConditionColor(widget.condition),
                ),

              // Transaction Type Badge (Buy/Swap)
              if (widget.transactionType != null)
                _buildTag(
                  widget.transactionType == 'sell'
                      ? 'Buy${widget.price != null ? ' - \$${widget.price!.toStringAsFixed(0)}' : ''}'
                      : 'Swap',
                  color: widget.transactionType == 'sell'
                      ? Colors.orange[800]
                      : Colors.deepPurple,
                ),
            ],
          ),
          SizedBox(height: 8.h),

          // Footer (Location & Date)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.location ?? 'No location',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.distance != null)
                      Text(
                        '${widget.distance!.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                _formatDate(widget.createdAt),
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onEdit,
              icon: Icon(Icons.edit_outlined, size: 16.w),
              label: const Text('Edit'),
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
              label: const Text('Delete'),
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
    );
  }

  Widget _buildTag(String text, {Color? color}) {
    if (text.isEmpty) return SizedBox.shrink();

    final tagColor = color ?? Colors.grey[100]!;
    final textColor =
        color != null ? tagColor.withOpacity(1.0) : Colors.black87;
    final backgroundColor =
        color != null ? tagColor.withOpacity(0.1) : Colors.grey[100];

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
