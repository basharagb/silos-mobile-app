import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/api_service.dart';

class WeatherStationWidget extends StatefulWidget {
  const WeatherStationWidget({super.key});

  @override
  State<WeatherStationWidget> createState() => _WeatherStationWidgetState();
}

class _WeatherStationWidgetState extends State<WeatherStationWidget>
    with TickerProviderStateMixin {
  WeatherStationData? _weatherData;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchWeatherData();
    // Refresh every 30 seconds
    _startPeriodicRefresh();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _fetchWeatherData();
        _startPeriodicRefresh();
      }
    });
  }

  Future<void> _fetchWeatherData() async {
    try {
      final data = await ApiService.getWeatherStationData();
      if (mounted) {
        setState(() {
          _weatherData = data;
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

  String _formatTemperature(double? temp) {
    if (temp == null || temp == -127.0) return 'Disconnected';
    return '${temp.toStringAsFixed(1)}°C';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.all(8.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF8E1),
                  Color(0xFFFFE0B2),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFFD7CCC8),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cottage Roof
              //_buildCottageRoof(),
                
                SizedBox(height: 18.h),
                
                // Main Content
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Inside Temperature
                    _buildTemperatureDisplay(
                      'INSIDE',
                      _weatherData?.insideTemp,
                      Colors.green,
                    ),
                    
                    // Cottage Window
                    _buildCottageWindow(),
                    
                    // Outside Temperature
                    _buildTemperatureDisplay(
                      'OUTSIDE',
                      _weatherData?.outsideTemp,
                      Colors.blue,
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // Weather Station Label
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D4037),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.orange : Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 1,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : null,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'WEATHER STATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: _isLoading ? Colors.orange : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCottageRoof() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main roof
        Container(
          width: 80.w,
          height: 40.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(40.r),
              topRight: Radius.circular(40.r),
            ),
          ),
        ),
        // Chimney with smoke
        Positioned(
          right: 10.w,
          top: -10.h,
          child: Column(
            children: [
              // Smoke animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -value * 10),
                    child: Opacity(
                      opacity: 1 - value,
                      child: Container(
                        width: 4.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Chimney
              Container(
                width: 8.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCottageWindow() {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF81D4FA), Color(0xFF4FC3F7)],
        ),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF8D6E63), width: 3),
      ),
      child: Stack(
        children: [
          // Window cross
          Center(
            child: Container(
              width: double.infinity,
              height: 2.h,
              color: const Color(0xFF8D6E63),
            ),
          ),
          Center(
            child: Container(
              width: 2.w,
              height: double.infinity,
              color: const Color(0xFF8D6E63),
            ),
          ),
          // Reflection effect
          Positioned(
            top: 4.h,
            left: 4.w,
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureDisplay(String label, double? temperature, Color color) {
    return Column(
      children: [
        // Label
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10.sp,
            ),
          ),
        ),
        
        SizedBox(height: 8.h),
        
        // Temperature display
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _formatTemperature(temperature),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
