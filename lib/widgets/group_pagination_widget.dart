import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GroupProgressBar extends StatelessWidget {
  final int currentGroup;
  final int totalGroups;
  final double overallProgress;
  final bool isRetryPhase;

  const GroupProgressBar({
    super.key,
    required this.currentGroup,
    required this.totalGroups,
    required this.overallProgress,
    this.isRetryPhase = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isRetryPhase ? Colors.orange.shade300 : Colors.blue.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isRetryPhase ? Colors.orange : Colors.blue).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRetryPhase ? 'Retry Progress' : 'Scan Progress',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isRetryPhase ? Colors.orange.shade800 : Colors.blue.shade800,
                ),
              ),
              Text(
                '${overallProgress.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isRetryPhase ? Colors.orange.shade800 : Colors.blue.shade800,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // Progress bar
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (overallProgress / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isRetryPhase 
                        ? [Colors.orange.shade400, Colors.orange.shade600]
                        : [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 8.h),
          
          // Group indicators
          Row(
            children: List.generate(totalGroups, (index) {
              Color color;
              if (index < currentGroup) {
                color = Colors.green.shade400; // Completed
              } else if (index == currentGroup) {
                color = isRetryPhase ? Colors.orange.shade400 : Colors.blue.shade400; // Current
              } else {
                color = Colors.grey.shade300; // Pending
              }
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class GroupPaginationWidget extends StatelessWidget {
  final int currentGroup;
  final int totalGroups;
  final Function(int) onGroupChanged;
  final bool isAutoTestRunning;

  const GroupPaginationWidget({
    super.key,
    required this.currentGroup,
    required this.totalGroups,
    required this.onGroupChanged,
    this.isAutoTestRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group indicator and navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous button
              IconButton(
                onPressed: currentGroup > 0 ? () => onGroupChanged(currentGroup - 1) : null,
                icon: Icon(
                  Icons.chevron_left,
                  color: currentGroup > 0 ? Colors.blue : Colors.grey,
                  size: 24.sp,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: currentGroup > 0 
                      ? Colors.blue.withOpacity(0.1) 
                      : Colors.grey.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              
              // Group info
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Group ${currentGroup + 1}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${currentGroup + 1} of $totalGroups',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isAutoTestRunning) ...[
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'AUTO SCANNING',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Next button
              IconButton(
                onPressed: currentGroup < totalGroups - 1 
                    ? () => onGroupChanged(currentGroup + 1) 
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  color: currentGroup < totalGroups - 1 ? Colors.blue : Colors.grey,
                  size: 24.sp,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: currentGroup < totalGroups - 1 
                      ? Colors.blue.withOpacity(0.1) 
                      : Colors.grey.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Numbered page buttons
          _buildNumberedPagination(),
          
          SizedBox(height: 8.h),
          
          // Quick navigation buttons
          if (totalGroups > 5)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickNavButton('First', 0, currentGroup != 0),
                _buildQuickNavButton('Last', totalGroups - 1, currentGroup != totalGroups - 1),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNumberedPagination() {
    const int maxVisiblePages = 7; // Show max 7 page buttons at once
    
    List<Widget> pageButtons = [];
    
    if (totalGroups <= maxVisiblePages) {
      // Show all pages if total is small
      for (int i = 0; i < totalGroups; i++) {
        pageButtons.add(_buildPageButton(i + 1, i));
      }
    } else {
      // Complex pagination with ellipsis
      int startPage = 0;
      int endPage = totalGroups - 1;
      
      if (currentGroup <= 3) {
        // Show: 1 2 3 4 5 ... 10
        endPage = 4;
        for (int i = startPage; i <= endPage; i++) {
          pageButtons.add(_buildPageButton(i + 1, i));
        }
        pageButtons.add(_buildEllipsis());
        pageButtons.add(_buildPageButton(totalGroups, totalGroups - 1));
      } else if (currentGroup >= totalGroups - 4) {
        // Show: 1 ... 6 7 8 9 10
        pageButtons.add(_buildPageButton(1, 0));
        pageButtons.add(_buildEllipsis());
        startPage = totalGroups - 5;
        for (int i = startPage; i < totalGroups; i++) {
          pageButtons.add(_buildPageButton(i + 1, i));
        }
      } else {
        // Show: 1 ... 4 5 6 ... 10
        pageButtons.add(_buildPageButton(1, 0));
        pageButtons.add(_buildEllipsis());
        
        for (int i = currentGroup - 1; i <= currentGroup + 1; i++) {
          pageButtons.add(_buildPageButton(i + 1, i));
        }
        
        pageButtons.add(_buildEllipsis());
        pageButtons.add(_buildPageButton(totalGroups, totalGroups - 1));
      }
    }
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4.w,
      children: pageButtons,
    );
  }
  
  Widget _buildPageButton(int pageNumber, int pageIndex) {
    final isActive = pageIndex == currentGroup;
    
    return GestureDetector(
      onTap: () => onGroupChanged(pageIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.white,
          border: Border.all(
            color: isActive ? Colors.blue : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(6.r),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        child: Center(
          child: Text(
            pageNumber.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontSize: 14.sp,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEllipsis() {
    return Container(
      width: 32.w,
      height: 32.w,
      child: Center(
        child: Text(
          '...',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNavButton(String label, int targetGroup, bool enabled) {
    return TextButton(
      onPressed: enabled ? () => onGroupChanged(targetGroup) : null,
      style: TextButton.styleFrom(
        foregroundColor: enabled ? Colors.blue : Colors.grey,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
