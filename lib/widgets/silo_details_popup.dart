import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';

class SiloDetailsPopup extends StatefulWidget {
  final int siloNumber;
  final VoidCallback? onClose;

  const SiloDetailsPopup({
    super.key,
    required this.siloNumber,
    this.onClose,
  });

  @override
  State<SiloDetailsPopup> createState() => _SiloDetailsPopupState();
}

class _SiloDetailsPopupState extends State<SiloDetailsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  SiloSensorData? _siloData;
  double? _grainLevel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSiloData();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadSiloData() async {
    try {
      final sensorData = await ApiService.getSiloSensorData(widget.siloNumber);
      
      if (mounted) {
        setState(() {
          _siloData = sensorData;
          _grainLevel = 75.0; // Mock grain level for now
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: _closePopup,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on popup content
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      width: 320.w,
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF10B981), Color(0xFF047857)],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20.r),
                                topRight: Radius.circular(20.r),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Silo ${widget.siloNumber}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _closePopup,
                                  child: Container(
                                    padding: EdgeInsets.all(4.w),
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Content
                          Padding(
                            padding: EdgeInsets.all(20.w),
                            child: _isLoading
                                ? _buildLoadingContent()
                                : _buildSiloContent(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return SizedBox(
      height: 200.h,
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
        ),
      ),
    );
  }

  Widget _buildSiloContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Temperature Section
        _buildSectionTitle('Temperature Readings'),
        SizedBox(height: 12.h),
        _buildTemperatureGrid(),
        
        SizedBox(height: 20.h),
        
        // Grain Level Section
        _buildSectionTitle('Grain Level'),
        SizedBox(height: 12.h),
        _buildGrainLevelInfo(),
        
        SizedBox(height: 20.h),
        
        // Status Section
        _buildSectionTitle('Status'),
        SizedBox(height: 12.h),
        _buildStatusInfo(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildTemperatureGrid() {
    if (_siloData == null) {
      return Text(
        'No temperature data available',
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey.shade600,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Max Temperature: ${_siloData!.maxTemp.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _getTemperatureColor(_siloData!.maxTemp),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          GridView.builder(
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
              final temp = _siloData!.sensors[index];
              final colorHex = index < _siloData!.sensorColors.length 
                  ? _siloData!.sensorColors[index] 
                  : null;
              
              return Container(
                decoration: BoxDecoration(
                  color: _getSensorColor(colorHex, temp),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'S${index + 1}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      temp == -127 ? 'N/A' : '${temp.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrainLevelInfo() {
    if (_grainLevel == null) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'No grain level data available',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fill Level',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${_grainLevel!.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Estimated Volume',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${(_grainLevel! * 10).toStringAsFixed(0)} tons',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    final status = _getOverallStatus();
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: status['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: status['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            status['icon'],
            color: status['color'],
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status['title'],
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: status['color'],
                  ),
                ),
                Text(
                  status['description'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp >= 40) return const Color(0xFFEF4444);
    if (temp >= 30) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  Color _getSensorColor(String? colorHex, double temperature) {
    if (colorHex != null && colorHex.isNotEmpty && colorHex != ApiService.wheatColor) {
      try {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fall back to temperature-based color
      }
    }

    // Temperature-based color logic
    if (temperature == -127.0) {
      return Colors.grey;
    } else if (temperature >= 40) {
      return const Color(0xFFEF4444);
    } else if (temperature >= 30) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF10B981);
    }
  }

  Map<String, dynamic> _getOverallStatus() {
    if (_siloData == null) {
      return {
        'title': 'Unknown',
        'description': 'No data available',
        'color': Colors.grey,
        'icon': Icons.help_outline,
      };
    }

    if (_siloData!.maxTemp >= 40) {
      return {
        'title': 'Critical Temperature',
        'description': 'Immediate attention required',
        'color': const Color(0xFFEF4444),
        'icon': Icons.warning,
      };
    } else if (_siloData!.maxTemp >= 30) {
      return {
        'title': 'Warning',
        'description': 'Monitor temperature closely',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.warning_amber,
      };
    } else {
      return {
        'title': 'Normal Operation',
        'description': 'All systems operating normally',
        'color': const Color(0xFF10B981),
        'icon': Icons.check_circle,
      };
    }
  }

  void _closePopup() {
    _animationController.reverse().then((_) {
      if (widget.onClose != null) {
        widget.onClose!();
      }
    });
  }
}
