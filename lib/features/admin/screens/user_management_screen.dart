// ignore_for_file: deprecated_member_use

import 'package:barter/features/authentication/models/user_model.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await FirebaseService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  Future<void> _changeUserRole(UserModel user) async {
    final newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(role.displayName),
              value: role,
              groupValue: user.role,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (newRole != null && newRole != user.role) {
      try {
        await FirebaseService.updateUserRole(userId: user.id, newRole: newRole);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated to ${newRole.displayName}'),
          ),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _suspendUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Text(
          'Are you sure you want to suspend ${user.name}? This will:\n\n'
          '• Mark all their products as unavailable\n'
          '• Reject all pending trades\n\n'
          'This action can be reversed by changing their role.',
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

    if (confirm == true) {
      try {
        await FirebaseService.suspendUser(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User suspended successfully')),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to permanently delete ${user.name}?\n\n'
          'This will delete:\n'
          '• User account\n'
          '• All their products\n'
          '• All their trades\n\n'
          'THIS ACTION CANNOT BE UNDONE!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.deleteUserData(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted successfully')),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addAdminToWhitelist() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Admin'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the email of the user you want to authorize as an Admin. When they register, they will be given Admin privileges automatically.',
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'admin@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Authorize'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.addToAdminWhitelist(emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email whitelisted! This user will be an Admin upon registration.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              ),
              onChanged: _filterUsers,
            ),
          ),

          // User List
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
                              onPressed: _loadUsers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(
                                  fontSize: 16.sp, color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUsers,
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return _buildUserCard(user);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAdminToWhitelist,
        icon: const Icon(Icons.add_moderator),
        label: const Text('Add Admin'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCurrentUser = user.id == UserModel.currentUser?.id;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: TextStyle(fontSize: 12.sp)),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                user.role.displayName,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ID: ${user.id}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Favourite Products: ${user.favouriteProductIds.length}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _changeUserRole(user),
                      icon: const Icon(Icons.admin_panel_settings, size: 18),
                      label: const Text('Change Role'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (!isCurrentUser) ...[
                      ElevatedButton.icon(
                        onPressed: () => _suspendUser(user),
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Suspend'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _deleteUser(user),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.moderator:
        return Colors.orange;
      case UserRole.premium:
        return Colors.purple;
      case UserRole.agent:
        return Colors.teal;
      case UserRole.user:
        return Colors.blue;
    }
  }
}
