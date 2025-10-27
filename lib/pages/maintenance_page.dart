import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/weather_station_widget.dart';
import '../widgets/maintenance_silo_grid.dart';
import '../widgets/maintenance_cable_popup.dart';
import '../widgets/group_pagination_widget.dart';
import '../controllers/auto_test_controller.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  late AutoTestController _autoTestController;
  int _selectedSilo = 112;
  int? _testingSilo;
  int? _selectedSiloForPopup;
  bool _showCablePopup = false;
  final TextEditingController _siloInputController = TextEditingController();
  
  // Maintenance data cache (for future use)
  // final Map<int, MaintenanceSiloData> _maintenanceDataCache = {};
  
  @override
  void initState() {
    super.initState();
    _autoTestController = AutoTestController();
    _siloInputController.text = _selectedSilo.toString();
    _initializeController();
  }
  
  Future<void> _initializeController() async {
    await _autoTestController.initialize();
  }
  
  @override
  void dispose() {
    _siloInputController.dispose();
    super.dispose();
  }

  void _handleSiloClick(int siloNumber) async {
    print('🔧 [MAINTENANCE PAGE] Silo $siloNumber clicked');
    
    // Start testing animation
    setState(() {
      _testingSilo = siloNumber;
      _selectedSilo = siloNumber;
      _siloInputController.text = siloNumber.toString();
    });

    // Simulate testing delay (like in React version)
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Show cable popup after testing
    setState(() {
      _testingSilo = null;
      _selectedSiloForPopup = siloNumber;
      _showCablePopup = true;
    });
  }

  void _handleCloseCablePopup() {
    setState(() {
      _showCablePopup = false;
      _selectedSiloForPopup = null;
    });
  }

  void _handleManualTest() {
    final siloNumber = int.tryParse(_siloInputController.text);
    if (siloNumber != null && siloNumber > 0) {
      _handleSiloClick(siloNumber);
    }
  }

  void _handleSiloInputChanged(String value) {
    final siloNumber = int.tryParse(value);
    if (siloNumber != null && siloNumber > 0) {
      setState(() {
        _selectedSilo = siloNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Weather Station at Top
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  child: const WeatherStationWidget(),
                ),
                
                // System Status Bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.cable,
                          color: Colors.blue.shade600,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cable Maintenance System',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[900],
                              ),
                            ),
                            Text(
                              'Click any silo to test cables and sensors',
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
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.h,
                              decoration: BoxDecoration(
                                color: Colors.green.shade500,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'System Online',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_testingSilo != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.yellow.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.science,
                                size: 12.sp,
                                color: Colors.yellow.shade700,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Testing Silo $_testingSilo',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.yellow.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Main Content Area
                Expanded(
                  child: Column(
                    children: [
                      // Silo Grid
                      Expanded(
                        child: MaintenanceSiloGrid(
                          onSiloClick: _handleSiloClick,
                          selectedSilo: _selectedSilo,
                          testingSilo: _testingSilo,
                          autoTestController: _autoTestController,
                        ),
                      ),
                      
                      // Group Pagination
                      AnimatedBuilder(
                        animation: _autoTestController,
                        builder: (context, child) {
                          return GroupPaginationWidget(
                            currentGroup: _autoTestController.currentGroupIndex + 1,
                            totalGroups: _autoTestController.totalGroups,
                            onGroupChanged: (group) {
                              _autoTestController.navigateToGroup(group - 1);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Manual Test Controls
                Container(
                  margin: EdgeInsets.all(16.w),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.build,
                            size: 16.sp,
                            color: Colors.grey[700],
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Manual Test',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _siloInputController,
                              keyboardType: TextInputType.number,
                              onChanged: _handleSiloInputChanged,
                              decoration: InputDecoration(
                                hintText: 'Silo #',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide(color: Colors.blue.shade400),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          ElevatedButton(
                            onPressed: _handleManualTest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 12.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'Test',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedSiloForPopup != null) ...[
                        SizedBox(height: 8.h),
                        Text(
                          'Last tested: Silo $_selectedSiloForPopup',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Cable Popup Overlay
          if (_showCablePopup && _selectedSiloForPopup != null)
            MaintenanceCablePopup(
              siloNumber: _selectedSiloForPopup!,
              onClose: _handleCloseCablePopup,
            ),
        ],
      ),
    );
  }
}
