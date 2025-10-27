import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/auto_test_controller.dart';
import '../services/maintenance_api_service.dart';

class MaintenanceSiloGrid extends StatefulWidget {
  final Function(int) onSiloClick;
  final int selectedSilo;
  final int? testingSilo;
  final AutoTestController autoTestController;

  const MaintenanceSiloGrid({
    super.key,
    required this.onSiloClick,
    required this.selectedSilo,
    this.testingSilo,
    required this.autoTestController,
  });

  @override
  State<MaintenanceSiloGrid> createState() => _MaintenanceSiloGridState();
}

class _MaintenanceSiloGridState extends State<MaintenanceSiloGrid> {
  // Cache for maintenance data
  final Map<int, MaintenanceSiloData> _maintenanceCache = {};
  final Set<int> _loadingSilos = {};

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.autoTestController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // Group Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5F5F5), Color(0xFFE8F5E8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.cable,
                        color: Colors.green.shade600,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group ${widget.autoTestController.currentGroupIndex + 1}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          Text(
                            'Cable maintenance and sensor testing',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '${_getSilosInCurrentGroup().length} Silos',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Silo Grid
              Expanded(
                child: _buildSiloGrid(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSiloGrid() {
    final silosInGroup = _getSilosInCurrentGroup();
    
    if (silosInGroup.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cable_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              'No silos in this group',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 5 silos per row (like React version)
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.0,
      ),
      itemCount: silosInGroup.length,
      itemBuilder: (context, index) {
        final siloNumber = silosInGroup[index];
        return _buildSiloCard(siloNumber);
      },
    );
  }

  Widget _buildSiloCard(int siloNumber) {
    final isSelected = widget.selectedSilo == siloNumber;
    final isTesting = widget.testingSilo == siloNumber;
    final isLoading = _loadingSilos.contains(siloNumber);
    final maintenanceData = _maintenanceCache[siloNumber];
    
    // Determine silo color based on maintenance data or default
    Color siloColor = Colors.grey.shade300; // Default unscanned color
    if (maintenanceData != null) {
      siloColor = _parseColor(maintenanceData.siloColor);
    } else if (isTesting || isLoading) {
      siloColor = Colors.blue.shade400; // Testing color
    }

    return GestureDetector(
      onTap: () => _handleSiloTap(siloNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: siloColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? Colors.blue.shade600 : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Silo Number
            Center(
              child: Text(
                siloNumber.toString(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(siloColor),
                ),
              ),
            ),
            
            // Testing Indicator
            if (isTesting || isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            // Cable Status Indicator
            if (maintenanceData != null)
              Positioned(
                top: 4.h,
                right: 4.w,
                child: Container(
                  width: 12.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: _getCableStatusColor(maintenanceData),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            
            // Silo Type Indicator (Circular vs Square)
            Positioned(
              bottom: 4.h,
              left: 4.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _getSiloType(siloNumber),
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSiloTap(int siloNumber) async {
    // Add to loading set
    setState(() {
      _loadingSilos.add(siloNumber);
    });

    try {
      // Fetch maintenance data if not cached
      if (!_maintenanceCache.containsKey(siloNumber)) {
        final data = await MaintenanceApiService.fetchMaintenanceSiloData(siloNumber);
        _maintenanceCache[siloNumber] = data;
      }
    } catch (error) {
      print('🚨 [MAINTENANCE GRID] Failed to fetch data for silo $siloNumber: $error');
      // Generate simulated data as fallback
      _maintenanceCache[siloNumber] = MaintenanceApiService.generateSimulatedMaintenanceData(siloNumber);
    } finally {
      // Remove from loading set
      setState(() {
        _loadingSilos.remove(siloNumber);
      });
    }

    // Call the parent callback
    widget.onSiloClick(siloNumber);
  }

  List<int> _getSilosInCurrentGroup() {
    final currentGroup = widget.autoTestController.currentGroupIndex + 1;
    final silosPerGroup = 20; // 20 silos per group (like React version)
    final startSilo = ((currentGroup - 1) * silosPerGroup) + 1;
    final endSilo = currentGroup * silosPerGroup;
    
    // Generate silo numbers for the current group
    final silos = <int>[];
    for (int i = startSilo; i <= endSilo; i++) {
      // Skip silo numbers that don't exist (e.g., 62-100, 190+)
      if (_isValidSiloNumber(i)) {
        silos.add(i);
      }
    }
    
    return silos;
  }

  bool _isValidSiloNumber(int siloNumber) {
    // Circular silos: 1-61
    // Square silos: 101-189
    return (siloNumber >= 1 && siloNumber <= 61) || 
           (siloNumber >= 101 && siloNumber <= 189);
  }

  String _getSiloType(int siloNumber) {
    if (siloNumber >= 1 && siloNumber <= 61) {
      return 'C'; // Circular
    } else if (siloNumber >= 101 && siloNumber <= 189) {
      return 'S'; // Square
    }
    return '?';
  }

  Color _parseColor(String colorString) {
    try {
      // Remove # if present
      final cleanColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      return Colors.grey.shade300; // Default color
    }
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate luminance to determine if text should be black or white
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Color _getCableStatusColor(MaintenanceSiloData data) {
    // Check if any sensors are disconnected (-127)
    final hasDisconnectedSensors = data.sensorValues.any((value) => value == -127);
    if (hasDisconnectedSensors) {
      return Colors.red;
    }
    
    // Check for critical temperatures
    final hasCriticalTemps = data.sensorColors.any((color) => color == '#d14141');
    if (hasCriticalTemps) {
      return Colors.red;
    }
    
    // Check for warning temperatures
    final hasWarningTemps = data.sensorColors.any((color) => color == '#ff9800');
    if (hasWarningTemps) {
      return Colors.orange;
    }
    
    return Colors.green; // All normal
  }
}
