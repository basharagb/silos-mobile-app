import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../services/api_service.dart';

class AnimatedSensorReadings extends StatefulWidget {
  final int selectedSilo;
  final bool isReading;
  final VoidCallback? onRefresh;

  const AnimatedSensorReadings({
    super.key,
    required this.selectedSilo,
    this.isReading = false,
    this.onRefresh,
  });

  @override
  State<AnimatedSensorReadings> createState() => _AnimatedSensorReadingsState();
}

class _AnimatedSensorReadingsState extends State<AnimatedSensorReadings>
    with TickerProviderStateMixin {
  SiloSensorData? _sensorData;
  bool _isLoading = false;
  Timer? _refreshTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchSensorData();
    _startPeriodicRefresh();
  }

  @override
  void didUpdateWidget(AnimatedSensorReadings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSilo != widget.selectedSilo) {
      _fetchSensorData();
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !widget.isReading) {
        _fetchSensorData();
      }
    });
  }

  Future<void> _fetchSensorData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.getSiloSensorData(widget.selectedSilo);
      if (mounted) {
        setState(() {
          _sensorData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getTemperatureColorFromHex(String? colorHex, double temperature) {
    // Use API color if available (matching React logic)
    if (colorHex != null && colorHex.isNotEmpty && colorHex != ApiService.wheatColor) {
      try {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fall back to temperature-based color
      }
    }

    // Temperature-based color logic (matching React implementation)
    if (temperature == -127.0) {
      return Colors.grey; // Disconnected sensors
    } else if (temperature == 0) {
      return Color(int.parse(ApiService.wheatColor.replaceFirst('#', '0xFF'))); // Unloaded (beige)
    } else if (temperature >= 40) {
      return const Color(0xFFF44336); // Red/Pink (critical) - temp-pink
    } else if (temperature >= 30) {
      return const Color(0xFFFFC107); // Yellow (warning) - temp-yellow  
    } else {
      return const Color(0xFF4CAF50); // Green (normal) - temp-green
    }
  }

  // Get gradient colors for sensor background (matching React CSS gradients)
  LinearGradient _getTemperatureGradient(double temperature) {
    if (temperature == -127.0) {
      // Gray gradient for disconnected
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9ca3af), Color(0xFF6b7280)],
      );
    } else if (temperature == 0) {
      // Beige gradient for unloaded
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5DEB3), Color(0xFFe6d0a3)],
      );
    } else if (temperature >= 40) {
      // Red/Pink gradient for critical
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF44336), Color(0xFFda190b)],
      );
    } else if (temperature >= 30) {
      // Yellow gradient for warning
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFC107), Color(0xFFe0a800)],
      );
    } else {
      // Green gradient for normal
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
      );
    }
  }

  String _formatTemperature(double temperature) {
    if (temperature <= 0 || temperature == -127.0) {
      return 'N/A';
    }
    return '${temperature.toStringAsFixed(1)}°C';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.green.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Silo Sensors',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (widget.isReading)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'READING',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              // Refresh button
              GestureDetector(
                onTap: () {
                  _fetchSensorData();
                  widget.onRefresh?.call();
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: 20.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Silo number and max temp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isReading 
                    ? 'Reading Silo: ${widget.selectedSilo}'
                    : 'Silo: ${widget.selectedSilo}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isReading ? Colors.blue : Colors.grey.shade700,
                ),
              ),
              if (_sensorData != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getTemperatureColorFromHex(_sensorData!.siloColor, _sensorData!.maxTemp),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Max: ${_sensorData!.maxTemp.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 16.h),

          // Animated sensors grid
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: const CircularProgressIndicator(),
              ),
            )
          else if (_sensorData != null)
            _buildAnimatedSensorsGrid()
          else
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 32.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'No sensor data available',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSensorsGrid() {
    return Column(
      children: List.generate(8, (index) {
        final sensorNumber = 8 - index; // S8 at top, S1 at bottom (reversed order)
        final sensorIndex = sensorNumber - 1;
        final temperature = _sensorData!.sensors[sensorIndex];
        final colorHex = sensorIndex < _sensorData!.sensorColors.length 
            ? _sensorData!.sensorColors[sensorIndex] 
            : null;
        final color = _getTemperatureColorFromHex(colorHex, temperature);

        return Container(
          margin: EdgeInsets.symmetric(vertical: 2.h),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: _getTemperatureGradient(temperature),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Blue overlay for reading state (matching React bg-blue-100 bg-opacity-40)
                if (widget.isReading)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFdbeafe).withOpacity(0.4), // bg-blue-100 equivalent
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                // Sensor content
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'S$sensorNumber:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                      widget.isReading
                          ? AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Text(
                                    _formatTemperature(temperature),
                                    style: TextStyle(
                                      color: const Color(0xFF2563eb), // text-blue-600 equivalent
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Text(
                              _formatTemperature(temperature),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
