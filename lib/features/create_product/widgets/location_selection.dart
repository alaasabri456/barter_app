import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/services/location_service.dart';
import '../../../core/widgets/custom_dialog.dart';
import '../../../core/widgets/map_picker.dart';
import '../../authentication/widgets/auth_text_field.dart';

class LocationSelection extends StatefulWidget {
  final TextEditingController controller;
  final double? latitude;
  final double? longitude;
  final Function(double? lat, double? lng, String address) onLocationChanged;

  const LocationSelection({
    super.key,
    required this.controller,
    this.latitude,
    this.longitude,
    required this.onLocationChanged,
  });

  @override
  State<LocationSelection> createState() => _LocationSelectionState();
}

class _LocationSelectionState extends State<LocationSelection> {
  Timer? _debounce;
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onLocationSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().length < 3) {
        if (!mounted) return;
        setState(() => _locationSuggestions = []);
        return;
      }

      if (!mounted) return;
      setState(() => _isSearchingLocation = true);
      try {
        final suggestions = await LocationService.searchLocations(query);
        if (!mounted) return;
        setState(() => _locationSuggestions = suggestions);
      } finally {
        if (mounted) setState(() => _isSearchingLocation = false);
      }
    });
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final lat = double.tryParse(suggestion['lat'].toString());
    final lon = double.tryParse(suggestion['lon'].toString());
    final address = suggestion['display_name'] ?? '';

    widget.controller.text = address;
    widget.onLocationChanged(lat, lon, address);

    setState(() => _locationSuggestions = []);
    FocusScope.of(context).unfocus();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      final address = await LocationService.getAddressFromCoordinates(
          position.latitude, position.longitude);

      if (!mounted) return;
      if (address != null) {
        widget.controller.text = address;
        widget.onLocationChanged(
            position.latitude, position.longitude, address);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location captured successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        showInfoDialog(
          context: context,
          title: 'Location Error',
          message: e.toString(),
          icon: Icons.location_off_outlined,
          iconColor: Theme.of(context).colorScheme.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<ll.LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPicker(
          initialLocation: (widget.latitude != null && widget.longitude != null) 
              ? ll.LatLng(widget.latitude!, widget.longitude!) 
              : null,
        ),
      ),
    );

    if (result != null && mounted) {
      final address = await LocationService.getAddressFromCoordinates(
        result.latitude,
        result.longitude,
      );

      if (address != null && mounted) {
        widget.controller.text = address;
        widget.onLocationChanged(result.latitude, result.longitude, address);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AuthTextField(
                label: 'Location',
                hint: 'Enter your location',
                controller: widget.controller,
                textInputAction: TextInputAction.done,
                onChanged: _onLocationSearch,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter or pick a location';
                  }
                  return null;
                },
                maxLines: null,
                minLines: 1,
                // Allow the field to expand with its content
                // Setting expands to true ensures the text field grows as needed
              ),
            ),
            SizedBox(width: 8.w),
            if (_isFetchingLocation)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              IconButton(
                onPressed: _fetchLocation,
                icon: Icon(Icons.my_location,
                    color: Theme.of(context).primaryColor),
                tooltip: 'Use My Location',
              ),
              IconButton(
                onPressed: _pickOnMap,
                icon: Icon(Icons.map_outlined,
                    color: Theme.of(context).primaryColor),
                tooltip: 'Pick on Map',
              ),
            ],
          ],
        ),
        if (_locationSuggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _locationSuggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _locationSuggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined, size: 20),
                  title: Text(
                    suggestion['display_name'] ?? '',
                    style: TextStyle(fontSize: 13.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        if (_isSearchingLocation)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (widget.latitude != null && widget.longitude != null) ...[
          SizedBox(height: 8.h),
          Text(
            'Coordinates Captured: ${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)}',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
