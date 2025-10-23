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

class LiveReadingsInterface extends StatefulWidget {
  const LiveReadingsInterface({super.key});

  @override
  State<LiveReadingsInterface> createState() => _LiveReadingsInterfaceState();
}

class _LiveReadingsInterfaceState extends State<LiveReadingsInterface> {
  late TestController _testController;
  late AutoTestController _autoTestController;
  int _selectedSilo = 112;
  final TextEditingController _siloInputController = TextEditingController();
  
  // Silo data cache
  final Map<int, SiloSensorData> _siloDataCache = {};
  
  @override
  void initState() {
    super.initState();
    _testController = TestController();
    _autoTestController = AutoTestController();
    _siloInputController.text = _selectedSilo.toString();
    _initializeControllers();
  }
  
  Future<void> _initializeControllers() async {
    await _autoTestController.initialize();
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

  Color getSiloColor(int num) {
    // During auto test, check silo state
    if (_autoTestController.isRunning) {
      if (_autoTestController.isSiloScanning(num)) {
        // Currently scanning silo - use blue color
        return Colors.blue;
      } else if (_autoTestController.isSiloCompleted(num)) {
        // Completed silo - use API color if available
        final cachedData = _siloDataCache[num];
        if (cachedData != null) {
          try {
            final colorHex = cachedData.siloColor;
            if (colorHex.isNotEmpty && colorHex != ApiService.wheatColor) {
              return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
            }
          } catch (e) {
            // Fall back to temperature-based color
          }
          
          // Temperature-based color logic
          if (cachedData.maxTemp <= 0 || cachedData.maxTemp == -127.0) {
            return Colors.grey; // Disconnected
          } else if (cachedData.maxTemp < 30) {
            return Colors.green; // Normal
          } else if (cachedData.maxTemp < 40) {
            return Colors.orange; // Warning
          } else {
            return Colors.red; // Critical
          }
        }
      } else if (_autoTestController.isSiloDisconnected(num)) {
        // Disconnected silo
        return Colors.red;
      }
      
      // Unscanned silo during auto test - use wheat color
      return Color(int.parse(ApiService.wheatColor.replaceFirst('#', '0xFF')));
    }
    
    // Normal operation (not during auto test)
    final cachedData = _siloDataCache[num];
    if (cachedData != null) {
      try {
        // Use API silo color if available
        final colorHex = cachedData.siloColor;
        if (colorHex.isNotEmpty && colorHex != ApiService.wheatColor) {
          print('🎨 [LIVE READINGS] Using API color for silo $num: $colorHex');
          return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
        }
      } catch (e) {
        // Fall back to temperature-based color
      }
      
      // Temperature-based color logic when API color is not available
      if (cachedData.maxTemp <= 0 || cachedData.maxTemp == -127.0) {
        return Colors.grey; // Disconnected
      } else if (cachedData.maxTemp < 30) {
        return Colors.green; // Normal
      } else if (cachedData.maxTemp < 40) {
        return Colors.orange; // Warning
      } else {
        return Colors.red; // Critical
      }
    }
    
    // Default wheat color when no data available
    return Color(int.parse(ApiService.wheatColor.replaceFirst('#', '0xFF')));
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
    
    // Always load fresh silo data when clicked to get real-time colors
    _loadSiloData(siloNumber);
    print('🔄 [LIVE READINGS] Loading fresh data for silo $siloNumber');
    
    // Show silo details popup
    _showSiloDetailsPopup(siloNumber);
    
    // Handle test mode
    if (_testController.currentMode == TestMode.manual && !_testController.isRunning) {
      _testController.startManualTest(siloNumber);
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
              child: AnimatedBuilder(
                animation: _autoTestController,
                builder: (context, child) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      children: [
                        // Control panel at top
                        _buildControlPanel(),
                        
                        SizedBox(height: 16.h),
                        
                        // Auto test progress bar
                        if (_autoTestController.isRunning)
                          GroupProgressBar(
                            currentGroup: _autoTestController.currentGroupIndex,
                            totalGroups: _autoTestController.totalGroups,
                            overallProgress: _autoTestController.progress,
                            isRetryPhase: _autoTestController.isRetryPhase,
                          ),
                        
                        if (_autoTestController.isRunning)
                          SizedBox(height: 16.h),
                        
                        // Current silo group with sensors and grain level panels
                        _buildCurrentSiloGroup(),
                        
                        SizedBox(height: 24.h),
                        
                        // Group pagination at bottom
                        GroupPaginationWidget(
                          currentGroup: _autoTestController.currentGroupIndex,
                          totalGroups: _autoTestController.totalGroups,
                          onGroupChanged: (index) => _autoTestController.navigateToGroup(index),
                          isAutoTestRunning: _autoTestController.isRunning,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.blue.shade300, width: 2),
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
          // Title
          Text(
            'Test Controls',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Silo input
          Row(
            children: [
              Text(
                'Silo:',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  controller: _siloInputController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  onSubmitted: (value) {
                    final siloNumber = int.tryParse(value);
                    if (siloNumber != null && siloNumber >= 1 && siloNumber <= 195) {
                      _onSiloTap(siloNumber);
                    }
                  },
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Test buttons
          ListenableBuilder(
            listenable: _testController,
            builder: (context, child) {
              return Column(
                children: [
                  // Manual test button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _testController.isRunning && _testController.currentMode == TestMode.auto
                          ? null
                          : () {
                              if (_testController.currentMode == TestMode.manual) {
                                _testController.stopTest();
                              } else {
                                _testController.toggleManualMode();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _testController.currentMode == TestMode.manual
                            ? Colors.orange
                            : Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        _testController.currentMode == TestMode.manual
                            ? 'Stop Manual (3s)'
                            : 'Manual Readings (3s)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Auto test button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _autoTestController,
                      builder: (context, child) {
                        return ElevatedButton(
                          onPressed: () async {
                            if (_autoTestController.isRunning) {
                              await _autoTestController.stopAutoTest();
                            } else {
                              await _autoTestController.startAutoTest();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _autoTestController.isRunning
                                ? Colors.red
                                : Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_autoTestController.isRunning) ...[
                                SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                              ],
                              Text(
                                _autoTestController.isRunning
                                    ? _autoTestController.isRetryPhase
                                        ? 'Stop Auto Test (Retry ${_autoTestController.retryCount}/${_autoTestController.maxRetries})'
                                        : 'Stop Auto Test (${_autoTestController.progress.toStringAsFixed(1)}%)'
                                    : 'Start Auto Test (24s per silo)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Progress indicator
                  if (_testController.isRunning) ...[
                    LinearProgressIndicator(
                      value: _testController.progress / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _testController.isRetryPhase ? Colors.orange : Colors.green,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${_testController.progress.toStringAsFixed(1)}% - ${_testController.status}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  // Disconnected silos info
                  if (_testController.disconnectedSilos.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        'Disconnected: ${_testController.disconnectedSilos.length} silos',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
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
          
          SizedBox(height: 16.h),
          
          // Silo Sensors section
          Text(
            'Silo Sensors',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          // Animated Silo Sensors Panel
          AnimatedBuilder(
            animation: _autoTestController,
            builder: (context, child) {
              return AnimatedSensorReadings(
                selectedSilo: _autoTestController.currentSilo ?? _selectedSilo,
                isReading: _autoTestController.isRunning,
                onRefresh: () => _loadSiloData(_autoTestController.currentSilo ?? _selectedSilo),
              );
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Animated Grain Level Panel
          AnimatedBuilder(
            animation: _autoTestController,
            builder: (context, child) {
              return AnimatedGrainLevel(
                selectedSilo: _autoTestController.currentSilo ?? _selectedSilo,
                isReading: _autoTestController.isRunning,
                onRefresh: () => _loadSiloData(_autoTestController.currentSilo ?? _selectedSilo),
              );
            },
          ),
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
              
              // Auto test progress state
              SiloProgressState progressState = SiloProgressState.idle;
              double progress = 0.0;
              
              if (_autoTestController.isSiloScanning(num)) {
                progressState = _autoTestController.isRetryPhase 
                    ? SiloProgressState.retry 
                    : SiloProgressState.scanning;
                progress = _autoTestController.getSiloProgress(num);
              } else if (_autoTestController.isSiloCompleted(num)) {
                progressState = SiloProgressState.completed;
                progress = 1.0;
              } else if (_autoTestController.isSiloDisconnected(num)) {
                progressState = SiloProgressState.disconnected;
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
