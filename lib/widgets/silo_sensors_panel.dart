import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';

class SiloSensorsPanel extends StatefulWidget {
  final int selectedSilo;
  final bool isReading;
  final VoidCallback? onRefresh;

  const SiloSensorsPanel({
    super.key,
    required this.selectedSilo,
    this.isReading = false,
    this.onRefresh,
  });

  @override
  State<SiloSensorsPanel> createState() => _SiloSensorsPanelState();
}

class _SiloSensorsPanelState extends State<SiloSensorsPanel>
    with TickerProviderStateMixin {
  SiloSensorData? _sensorData;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchSensorData();
  }

  @override
  void didUpdateWidget(SiloSensorsPanel oldWidget) {
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

  Color _getTemperatureColor(double temperature, String? colorHex) {
    // Use API color if available
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fall back to temperature-based color
      }
    }

    // Temperature-based color logic
    if (temperature <= 0 || temperature == -127.0) {
      return Colors.grey; // Disconnected
    } else if (temperature < 30) {
      return Colors.green; // Normal
    } else if (temperature < 40) {
      return Colors.orange; // Warning
    } else {
      return Colors.red; // Critical
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
                'Reading Silo: ${widget.selectedSilo}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (_sensorData != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getTemperatureColor(_sensorData!.maxTemp, _sensorData!.siloColor),
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

          // Sensors grid
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: const CircularProgressIndicator(),
              ),
            )
          else if (_sensorData != null)
            _buildSensorsGrid()
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

  Widget _buildSensorsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1.2,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        final sensorNumber = index + 1;
        final temperature = _sensorData!.sensors[index];
        final colorHex = _sensorData!.sensorColors[index];
        final color = _getTemperatureColor(temperature, colorHex);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'S$sensorNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _formatTemperature(temperature),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
