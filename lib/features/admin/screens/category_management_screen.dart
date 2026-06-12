import 'package:barter/features/admin/models/category_suggestion_model.dart';
import 'package:barter/features/authentication/models/user_model.dart';
import 'package:provider/provider.dart';
import '../../admin/viewmodels/admin_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<CategorySuggestion> _suggestions = [];
  List<CategorySuggestion> _filteredSuggestions = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  CategoryStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suggestions = await context.read<AdminViewModel>().getCategorySuggestions();
      setState(() {
        _suggestions = suggestions;
        _filteredSuggestions = suggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterSuggestions(String query) {
    setState(() {
      var filtered = _suggestions;

      // Filter by search query
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        filtered = filtered.where((suggestion) {
          return suggestion.suggestedName.toLowerCase().contains(lowerQuery) ||
              suggestion.suggestedByName.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      // Filter by status
      if (_selectedStatus != null) {
        filtered = filtered.where((s) => s.status == _selectedStatus).toList();
      }

      _filteredSuggestions = filtered;
    });
  }

  Future<void> _approveSuggestion(CategorySuggestion suggestion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Category'),
        content: Text(
          'Approve "${suggestion.suggestedName}" as a new category?\n\n'
          'This will:\n'
          '• Add it to the category list\n'
          '• Update all products using this custom category',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final admin = UserModel.currentUser!;
        await context.read<AdminViewModel>().approveCategorySuggestion(
          suggestionId: suggestion.id,
          adminId: admin.id,
          adminName: admin.name,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${suggestion.suggestedName}" approved!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSuggestions();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectSuggestion(CategorySuggestion suggestion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Category'),
        content: Text('Reject "${suggestion.suggestedName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final admin = UserModel.currentUser!;
        await context.read<AdminViewModel>().rejectCategorySuggestion(
          suggestionId: suggestion.id,
          adminId: admin.id,
          adminName: admin.name,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category suggestion rejected')),
        );
        _loadSuggestions();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                  ),
                  onChanged: (value) => _filterSuggestions(value),
                ),
                SizedBox(height: 12.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      SizedBox(width: 8.w),
                      ...CategoryStatus.values.map((status) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: _buildFilterChip(status.displayName, status),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Suggestions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64.sp,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16.h),
                            Text('Error: $_error'),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: _loadSuggestions,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredSuggestions.isEmpty
                        ? Center(
                            child: Text(
                              'No category suggestions found',
                              style: TextStyle(
                                  fontSize: 16.sp, color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadSuggestions,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              itemCount: _filteredSuggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = _filteredSuggestions[index];
                                return _buildSuggestionCard(suggestion);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, CategoryStatus? status) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
          _filterSuggestions(_searchController.text);
        });
      },
    );
  }

  Widget _buildSuggestionCard(CategorySuggestion suggestion) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = suggestion.status == CategoryStatus.pending;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    suggestion.suggestedName,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(suggestion.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    suggestion.status.displayName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _getStatusColor(suggestion.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Suggested by: ${suggestion.suggestedByName}',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey),
            ),
            Text(
              'Date: ${_formatDate(suggestion.createdAt)}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            if (suggestion.reviewedByName != null) ...[
              SizedBox(height: 4.h),
              Text(
                'Reviewed by: ${suggestion.reviewedByName}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
              ),
            ],
            if (isPending) ...[
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveSuggestion(suggestion),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectSuggestion(suggestion),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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

  Color _getStatusColor(CategoryStatus status) {
    switch (status) {
      case CategoryStatus.pending:
        return Colors.orange;
      case CategoryStatus.approved:
        return Colors.green;
      case CategoryStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
