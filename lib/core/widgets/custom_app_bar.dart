import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 20.sp,
        ),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor,
      elevation: elevation ?? Theme.of(context).appBarTheme.elevation,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}

class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final bool pinned;
  final bool floating;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.expandedHeight = 200.0,
    this.flexibleSpace,
    this.pinned = true,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 20.sp,
        ),
      ),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? Theme.of(context).appBarTheme.foregroundColor,
      expandedHeight: expandedHeight.h,
      flexibleSpace: flexibleSpace,
      pinned: pinned,
      floating: floating,
    );
  }
}

class CustomAppBarWithSearch extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final List<Widget>? actions;
  final bool showSearch;

  const CustomAppBarWithSearch({
    super.key,
    required this.title,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onSearchClear,
    this.actions,
    this.showSearch = false,
  });

  @override
  State<CustomAppBarWithSearch> createState() => _CustomAppBarWithSearchState();

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}

class _CustomAppBarWithSearchState extends State<CustomAppBarWithSearch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _searchController.clear();
        widget.onSearchClear?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return _isSearching
              ? FadeTransition(
            opacity: _animation,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7),
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontSize: 16.sp,
              ),
              onChanged: widget.onSearchChanged,
              autofocus: true,
            ),
          )
              : FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_animation),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20.sp,
              ),
            ),
          );
        },
      ),
      centerTitle: !_isSearching,
      actions: [
        if (widget.showSearch)
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
        if (widget.actions != null && !_isSearching) ...widget.actions!,
      ],
    );
  }
}