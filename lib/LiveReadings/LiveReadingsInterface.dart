import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/weather_station_widget.dart';
import '../widgets/animated_sensor_readings.dart';
import '../widgets/animated_grain_level.dart';
import '../widgets/silo_progress_indicator.dart';
import '../widgets/silo_details_popup.dart';
import '../widgets/group_pagination_widget.dart';
import '../controllers/test_controller.dart';
import '../controllers/auto_test_controller.dart';
import '../services/api_service.dart';
import '../services/automatic_monitoring_service.dart';

class LiveReadingsInterface extends StatefulWidget {
  const LiveReadingsInterface({super.key});

  @override
  State<LiveReadingsInterface> createState() => _LiveReadingsInterfaceState();
}

class _LiveReadingsInterfaceState extends State<LiveReadingsInterface> {
  late TestController _testController;
  late AutoTestController _autoTestController;
  late AutomaticMonitoringService _monitoringService;
  int _selectedSilo = 112;
  final TextEditingController _siloInputController = TextEditingController();
  
  // Silo data cache (now managed by monitoring service)
  final Map<int, SiloSensorData> _siloDataCache = {};
  
  // Scanning state management
  final Set<int> _scanningSilos = {};
  
  @override
  void initState() {
    super.initState();
    _testController = TestController();
    _autoTestController = AutoTestController();
    _monitoringService = AutomaticMonitoringService();
    _siloInputController.text = _selectedSilo.toString();
    _initializeControllers();
  }
  
  Future<void> _initializeControllers() async {
    await _autoTestController.initialize();
    
    // Start automatic monitoring service
    _monitoringService.startMonitoring();
    
    await _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    // Load data for selected silo
    await _loadSiloData(_selectedSilo);
  }
  
  Future<void> _loadSiloData(int siloNumber) async {
    try {
      print('📡 [LIVE READINGS] Fetching API data for silo $siloNumber...');
      final data = await ApiService.getSiloSensorData(siloNumber);
      if (data != null && mounted) {
        print('✅ [LIVE READINGS] Received data for silo $siloNumber: color=${data.siloColor}, maxTemp=${data.maxTemp}°C');
        setState(() {
          _siloDataCache[siloNumber] = data;
        });
      } else {
        print('❌ [LIVE READINGS] No data received for silo $siloNumber');
      }
    } catch (e) {
      print('❌ [LIVE READINGS] Error loading silo $siloNumber data: $e');
    }
  }

  Future<void> _loadSiloDataAndUpdateColor(int siloNumber) async {
    try {
      print('🎨 [LIVE READINGS] Fetching API data for color update during auto test - silo $siloNumber...');
      final data = await ApiService.getSiloSensorData(siloNumber);
      if (data != null && mounted) {
        print('✅ [LIVE READINGS] Updating color for silo $siloNumber: ${data.siloColor} (auto test continues)');
        setState(() {
          _siloDataCache[siloNumber] = data;
          // Force UI update to show new colors immediately
        });
      } else {
        print('❌ [LIVE READINGS] No data received for silo $siloNumber color update');
      }
    } catch (e) {
      print('❌ [LIVE READINGS] Error loading silo $siloNumber data for color update: $e');
    }
  }

  Color getSiloColor(int num) {
    // Check if monitoring service has cached data (scanned silos)
    final cachedData = _monitoringService.getCachedSiloData(num);
    
    if (cachedData != null) {
      // Scanned silo - use API color
      try {
        final colorHex = cachedData.siloColor;
        if (colorHex.isNotEmpty) {
          // Parse hex color properly: #93856b -> 0xFF93856b
          final cleanHex = colorHex.replaceAll('#', '');
          return Color(int.parse('FF$cleanHex', radix: 16));
        }
      } catch (e) {
        print('⚠️ [COLOR] Failed to parse API color for silo $num: ${cachedData.siloColor}, using wheat color');
      }
    }
    
    // Unscanned silo - always use wheat color (yellowish like wheat grain)
    final cleanWheatHex = ApiService.wheatColor.replaceAll('#', '');
    return Color(int.parse('FF$cleanWheatHex', radix: 16));
  }
  
  /// Check if silo has been scanned (has cached data)
  bool isSiloScanned(int num) {
    return _monitoringService.getCachedSiloData(num) != null;
  }
  
  /// Check if silo is currently being scanned
  bool isSiloScanning(int num) {
    // Check if it's being scanned manually
    if (_scanningSilos.contains(num)) {
      return true;
    }
    
    // Check if it's being scanned in initial scan
    if (_monitoringService.isInitialScanning) {
      return _monitoringService.currentInitialScanSilo == num;
    }
    
    return false;
  }

  bool isSquare(int num) {
    const squareNumbers = [
      4, 2, 8, 10, 21, 19, 17, 15, 13,
      43, 41, 39, 37, 35, 32, 30, 28, 26, 24,
      175, 171, 168, 164, 161, 156, 152, 149, 145, 142,
      137, 133, 130, 126, 123, 118, 114, 111, 107, 104,
      194, 190, 187, 183, 180
    ];
    return squareNumbers.contains(num);
  }
  
  void _onSiloTap(int siloNumber) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSilo = siloNumber;
      _siloInputController.text = siloNumber.toString();
    });
    
    // Show silo details popup
    _showSiloDetailsPopup(siloNumber);
    
    // Trigger on-demand update for this silo
    _updateSiloOnDemand(siloNumber);
  }

  Future<void> _updateSiloOnDemand(int siloNumber) async {
    print('🎯 [LIVE READINGS] On-demand update for silo $siloNumber');
    
    // Mark silo as scanning and show progress indicator
    setState(() {
      _scanningSilos.add(siloNumber);
    });
    
    try {
      // Use monitoring service for on-demand updates
      final data = await _monitoringService.updateSiloOnDemand(siloNumber);
      
      if (data != null) {
        // Update local cache as well for compatibility
        setState(() {
          _siloDataCache[siloNumber] = data;
        });
        print('✅ [LIVE READINGS] On-demand update completed for silo $siloNumber');
      } else {
        print('❌ [LIVE READINGS] On-demand update failed for silo $siloNumber');
      }
    } finally {
      // Remove scanning state
      setState(() {
        _scanningSilos.remove(siloNumber);
      });
    }
  }

  void _showSiloDetailsPopup(int siloNumber) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SiloDetailsPopup(
        siloNumber: siloNumber,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
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

  @override
  void dispose() {
    _testController.dispose();
    _autoTestController.dispose();
    _siloInputController.dispose();
    // Note: Don't dispose monitoring service as it's a singleton
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Weather Station at the top
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.w),
              child: const WeatherStationWidget(),
            ),
            
            // Main content area - Paginated layout
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  children: [
                    // Monitoring status indicator - separate AnimatedBuilder with error boundary
                    Builder(
                      builder: (context) {
                        try {
                          return AnimatedBuilder(
                            animation: _monitoringService,
                            builder: (context, child) => _buildMonitoringStatusIndicator(),
                          );
                        } catch (e) {
                          debugPrint('❌ [EMERGENCY] Monitoring status widget error: $e');
                          return Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.orange.shade300, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning, color: Colors.orange.shade800, size: 20.w),
                                SizedBox(width: 8.w),
                                Text(
                                  'Monitoring Service (Safe Mode)',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                    
                    SizedBox(height: 16.h),
                    
                    // Current silo group with sensors and grain level panels - separate AnimatedBuilder with error boundary
                    Builder(
                      builder: (context) {
                        try {
                          return AnimatedBuilder(
                            animation: _autoTestController,
                            builder: (context, child) => _buildCurrentSiloGroup(),
                          );
                        } catch (e) {
                          debugPrint('❌ [EMERGENCY] Silo group widget error: $e');
                          return Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: Colors.red.shade300, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error, color: Colors.red.shade800, size: 20.w),
                                SizedBox(width: 8.w),
                                Text(
                                  'Silo Display (Safe Mode)',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                    
                    SizedBox(height: 24.h),
                    
                    // Group pagination at bottom - separate AnimatedBuilder
                    AnimatedBuilder(
                      animation: _autoTestController,
                      builder: (context, child) => GroupPaginationWidget(
                        currentGroup: _autoTestController.currentGroupIndex,
                        totalGroups: _autoTestController.totalGroups,
                        onGroupChanged: (index) => _autoTestController.navigateToGroup(index),
                        isAutoTestRunning: false, // No longer using auto test
                      ),
                    ),

                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringStatusIndicator() {
    final stats = _monitoringService.getMonitoringStats();
    final isRunning = _monitoringService.isRunning;
    final isBatchChecking = _monitoringService.isBatchChecking;
    final isInitialScanning = _monitoringService.isInitialScanning;
    final currentInitialScanIndex = _monitoringService.currentInitialScanIndex;
    final currentInitialScanSilo = _monitoringService.currentInitialScanSilo;
    final lastCheck = _monitoringService.lastBatchCheck;
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isRunning ? Colors.green.shade300 : Colors.grey.shade300, 
          width: 2
        ),
        boxShadow: [
          BoxShadow(
            color: (isRunning ? Colors.green : Colors.grey).withOpacity(0.2),
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
                isInitialScanning ? Icons.scanner : (isRunning ? Icons.autorenew : Icons.pause_circle_outline),
                color: isInitialScanning ? Colors.blue : (isRunning ? Colors.green : Colors.grey),
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                isInitialScanning ? 'Initial Scan' : 'Automatic Monitoring',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isInitialScanning ? Colors.blue.shade800 : (isRunning ? Colors.green.shade800 : Colors.grey.shade600),
                ),
              ),
              if (isBatchChecking || isInitialScanning) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(isInitialScanning ? Colors.blue : Colors.green),
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
              if (isInitialScanning) ...[
                _buildStatusItem(
                  'Progress',
                  '${currentInitialScanIndex}/${stats['totalSilos']}',
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildStatusItem(
                  'Current',
                  currentInitialScanSilo?.toString() ?? '-',
                  Icons.gps_fixed,
                  Colors.orange,
                ),
                _buildStatusItem(
                  'Speed',
                  '1s/silo',
                  Icons.speed,
                  Colors.green,
                ),
              ] else ...[
                _buildStatusItem(
                  'Interval',
                  '3 min',
                  Icons.timer,
                  Colors.blue,
                ),
                _buildStatusItem(
                  'Cached',
                  '${stats['cachedSilos']}/${stats['totalSilos']}',
                  Icons.storage,
                  Colors.orange,
                ),
                _buildStatusItem(
                  'Fresh',
                  '${stats['freshSilos']}',
                  Icons.refresh,
                  Colors.green,
                ),
              ],
            ],
          ),
          
          if (lastCheck != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Last check: ${_formatLastCheck(lastCheck)}',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          
          if (isInitialScanning) ...[
            SizedBox(height: 8.h),
            // Progress bar for initial scan
            LinearProgressIndicator(
              value: currentInitialScanIndex / stats['totalSilos'],
              backgroundColor: Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 4.h),
            Text(
              'Scanning silo ${currentInitialScanSilo ?? '...'} (${currentInitialScanIndex}/${stats['totalSilos']})',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (isBatchChecking) ...[
            SizedBox(height: 8.h),
            Text(
              'Checking all silos...',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.green.shade600,
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
  
  String _formatLastCheck(DateTime lastCheck) {
    final now = DateTime.now();
    final diff = now.difference(lastCheck);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ${diff.inMinutes % 60}m ago';
    }
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
          
          SizedBox(height: 16.h),
          
          // // Silo Sensors section
          // Text(
          //   'Silo Sensors',
          //   style: TextStyle(
          //     fontSize: 16.sp,
          //     fontWeight: FontWeight.w600,
          //     color: Colors.grey.shade700,
          //   ),
          // ),
          //
          // SizedBox(height: 8.h),
          //
          // // Animated Silo Sensors Panel
          // AnimatedBuilder(
          //   animation: _autoTestController,
          //   builder: (context, child) {
          //     return AnimatedSensorReadings(
          //       selectedSilo: _autoTestController.currentSilo ?? _selectedSilo,
          //       isReading: _autoTestController.isRunning,
          //       onRefresh: () => _loadSiloData(_autoTestController.currentSilo ?? _selectedSilo),
          //     );
          //   },
          // ),
          
          // SizedBox(height: 16.h),
          //
          // // Animated Grain Level Panel
          // AnimatedBuilder(
          //   animation: _autoTestController,
          //   builder: (context, child) {
          //     return AnimatedGrainLevel(
          //       selectedSilo: _autoTestController.currentSilo ?? _selectedSilo,
          //       isReading: _autoTestController.isRunning,
          //       onRefresh: () => _loadSiloData(_autoTestController.currentSilo ?? _selectedSilo),
          //     );
          //   },
          // ),
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
}
