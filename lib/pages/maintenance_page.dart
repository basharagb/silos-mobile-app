import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/weather_station_widget.dart';
import '../widgets/maintenance_cable_popup.dart';
import '../widgets/group_pagination_widget.dart';
import '../widgets/silo_progress_indicator.dart';
import '../controllers/auto_test_controller.dart';
import '../services/maintenance_api_service.dart';
import '../services/api_service.dart';
import '../services/automatic_monitoring_service.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  late AutoTestController _autoTestController;
  late AutomaticMonitoringService _monitoringService;
  int _selectedSilo = 112; // Keep for potential future use
  int? _testingSilo;
  int? _selectedSiloForPopup;
  bool _showCablePopup = false;
  
  // Maintenance data cache
  final Map<int, MaintenanceSiloData> _maintenanceDataCache = {};
  final Set<int> _scanningSilos = {};
  
  @override
  void initState() {
    super.initState();
    _autoTestController = AutoTestController();
    _monitoringService = AutomaticMonitoringService();
    _initializeController();
  }
  
  Future<void> _initializeController() async {
    await _autoTestController.initialize();
  }
  
  @override
  void dispose() {
    _autoTestController.dispose();
    super.dispose();
  }

  void _onSiloTap(int siloNumber) async {
    print('🔧 [MAINTENANCE PAGE] Silo $siloNumber clicked');
    
    // Start testing animation
    setState(() {
      _testingSilo = siloNumber;
      _selectedSilo = siloNumber;
      _scanningSilos.add(siloNumber);
    });

    // Simulate testing delay and fetch maintenance data
    await Future.delayed(const Duration(milliseconds: 1000));
    
    try {
      // Fetch maintenance data if not cached
      if (!_maintenanceDataCache.containsKey(siloNumber)) {
        final data = await MaintenanceApiService.fetchMaintenanceSiloData(siloNumber);
        _maintenanceDataCache[siloNumber] = data;
      }
    } catch (error) {
      print('🚨 [MAINTENANCE] Failed to fetch data for silo $siloNumber: $error');
      // Generate simulated data as fallback
      _maintenanceDataCache[siloNumber] = MaintenanceApiService.generateSimulatedMaintenanceData(siloNumber);
    }
    
    // Show cable popup after testing
    setState(() {
      _testingSilo = null;
      _scanningSilos.remove(siloNumber);
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

  bool isSquare(int num) {
    // Based on web interface layout - exact mapping of square silos
    const squareNumbers = [
      // Group 1: Row 2 (middle row) - all square
      2, 4, 6, 8, 10,
      
      // Group 2: Row 2 (middle row) - all square  
      13, 15, 17, 19, 21,
      
      // Group 3: Row 2 (middle row) - all square
      24, 26, 28, 30, 32,
      
      // Group 4: Row 2 (middle row) - all square
      35, 37, 39, 41, 43,
      
      // Group 5: Row 2 (middle row) - all square
      46, 48, 50, 52, 54,
      
      // Groups 6-10: All silos are square (101-195)
      101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119,
      120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138,
      139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157,
      158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176,
      177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195
    ];
    return squareNumbers.contains(num);
  }

  bool isSiloScanning(int num) {
    return _testingSilo == num || _scanningSilos.contains(num);
  }

  bool isSiloScanned(int num) {
    return _maintenanceDataCache.containsKey(num);
  }

  Color getSiloColor(int num) {
    // First check if Live Readings has cached data (shared cache)
    final liveReadingsData = _monitoringService.getCachedSiloData(num);
    
    if (liveReadingsData != null) {
      // Use color from Live Readings cache for consistency
      try {
        final colorHex = liveReadingsData.siloColor;
        if (colorHex.isNotEmpty) {
          final cleanHex = colorHex.replaceAll('#', '');
          return Color(int.parse('FF$cleanHex', radix: 16));
        }
      } catch (e) {
        print('⚠️ [MAINTENANCE COLOR] Failed to parse Live Readings color for silo $num: ${liveReadingsData.siloColor}');
      }
    }
    
    // Fallback to maintenance-specific data if no Live Readings data
    final maintenanceData = _maintenanceDataCache[num];
    if (maintenanceData != null) {
      try {
        final colorString = maintenanceData.siloColor.replaceAll('#', '');
        return Color(int.parse('FF$colorString', radix: 16));
      } catch (e) {
        print('⚠️ [MAINTENANCE COLOR] Failed to parse maintenance color for silo $num');
      }
    }
    
    if (isSiloScanning(num)) {
      // Currently scanning - blue color
      return Colors.blue.shade400;
    } else {
      // Unscanned silo - wheat color (yellowish like wheat grain)
      final cleanWheatHex = ApiService.wheatColor.replaceAll('#', '');
      return Color(int.parse('FF$cleanWheatHex', radix: 16));
    }
  }

  Widget _buildCurrentSiloGroup() {
    final currentGroupIndex = _autoTestController.currentGroupIndex;
    final siloGroups = [
      // Group 1
      [
        [11, 7, 3],
        [10, 8, 6, 4, 2],
        [9, 5, 1],
      ],
      // Group 2
      [
        [22, 18, 14],
        [21, 19, 17, 15, 13],
        [20, 16, 12],
      ],
      // Group 3
      [
        [33, 29, 25],
        [32, 30, 28, 26, 24],
        [31, 27, 23],
      ],
      // Group 4
      [
        [44, 40, 36],
        [43, 41, 39, 37, 35],
        [42, 38, 34],
      ],
      // Group 5
      [
        [55, 51, 47],
        [54, 52, 50, 48, 46],
        [53, 49, 45],
      ],
      // Group 6
      [
        [119, 112, 105],
        [118, 114, 111, 107, 104],
        [117, 110, 103],
        [116, 113, 109, 106, 102],
        [115, 108, 101],
      ],
      // Group 7
      [
        [138, 131, 124],
        [137, 133, 130, 126, 123],
        [136, 129, 122],
        [135, 132, 128, 125, 121],
        [134, 127, 120],
      ],
      // Group 8
      [
        [157, 150, 143],
        [156, 152, 149, 145, 142],
        [155, 148, 141],
        [154, 151, 147, 144, 140],
        [153, 146, 139],
      ],
      // Group 9
      [
        [176, 169, 162],
        [175, 171, 168, 164, 161],
        [174, 167, 160],
        [173, 170, 166, 163, 159],
        [172, 165, 158],
      ],
      // Group 10
      [
        [195, 188, 181],
        [194, 190, 187, 183, 180],
        [193, 186, 179],
        [192, 189, 185, 182, 178],
        [191, 184, 177],
      ],
    ];

    if (currentGroupIndex >= siloGroups.length) return const SizedBox.shrink();

    final currentGroup = siloGroups[currentGroupIndex];
    final groupSilos = currentGroup.expand((row) => row).toList();

    return _buildSiloGroupWithPanels(
      'Group ${currentGroupIndex + 1}',
      currentGroup,
      groupSilos,
    );
  }

  Widget _buildMaintenanceStatusIndicator() {
    final scannedCount = _maintenanceDataCache.length;
    final totalSilos = 195; // Total silos in system
    final isScanning = _testingSilo != null || _scanningSilos.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.blue.shade300, 
          width: 2
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title with status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cable,
                color: Colors.blue.shade600,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Cable Maintenance System',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              if (isScanning) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Status info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(
                'Tested',
                '$scannedCount/$totalSilos',
                Icons.cable,
                Colors.blue,
              ),
              _buildStatusItem(
                'Current',
                _testingSilo?.toString() ?? '-',
                Icons.gps_fixed,
                Colors.orange,
              ),
              _buildStatusItem(
                'Mode',
                'Manual',
                Icons.touch_app,
                Colors.green,
              ),
            ],
          ),
          
          if (isScanning) ...[
            SizedBox(height: 8.h),
            Text(
              'Testing silo ${_testingSilo ?? '...'}',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16.w),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSiloGroupWithPanels(String groupName, List<List<int>> groups, List<int> siloNumbers) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group title
          Text(
            groupName,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Silo group display
          _buildGroupCard(groups),
        ],
      ),
    );
  }

  Widget _buildGroupCard(List<List<int>> groups) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.brown.shade200),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: groups.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((num) {
              bool square = isSquare(num);
              
              // Determine silo state based on scanning and cached data
              SiloProgressState progressState = SiloProgressState.idle;
              double progress = 0.0;
              
              // Check if silo is currently being scanned
              if (isSiloScanning(num)) {
                progressState = SiloProgressState.scanning;
                progress = 0.5; // Show scanning progress
              } else if (isSiloScanned(num)) {
                // Silo has been scanned and has cached data
                progressState = SiloProgressState.completed;
                progress = 1.0;
              } else {
                // Unscanned silo - show as idle with wheat color
                progressState = SiloProgressState.idle;
                progress = 0.0;
              }
              
              return SiloProgressIndicator(
                siloNumber: num,
                state: progressState,
                progress: progress,
                siloColor: getSiloColor(num),
                isSquare: square,
                onTap: () => _onSiloTap(num),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Column(
              children: [
                // Weather Station at the top
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.w),
                  child: const WeatherStationWidget(),
                ),
                
                // Main content area - Paginated layout
                Expanded(
                  child: AnimatedBuilder(
                    animation: _autoTestController,
                    builder: (context, child) {
                      return AnimatedBuilder(
                        animation: _monitoringService,
                        builder: (context, child) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.all(8.w),
                        child: Column(
                          children: [
                            // Maintenance status indicator
                            _buildMaintenanceStatusIndicator(),
                            
                            SizedBox(height: 16.h),
                            
                            // Current silo group
                            _buildCurrentSiloGroup(),
                            
                            SizedBox(height: 24.h),
                            
                            // Group pagination at bottom
                            GroupPaginationWidget(
                              currentGroup: _autoTestController.currentGroupIndex,
                              totalGroups: _autoTestController.totalGroups,
                              onGroupChanged: (index) => _autoTestController.navigateToGroup(index),
                              isAutoTestRunning: false,
                            ),

                            SizedBox(height: 16.h),
                          ],
                        ),
                      );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // Cable Popup Overlay
            if (_showCablePopup && _selectedSiloForPopup != null)
              MaintenanceCablePopup(
                siloNumber: _selectedSiloForPopup!,
                onClose: _handleCloseCablePopup,
              ),
          ],
        ),
      ),
    );
  }
}
