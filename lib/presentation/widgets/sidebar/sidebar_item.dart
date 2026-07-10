/// عنصر SideBar (NavItem) لتطبيق مكتب المحامي
/// 
/// هذا الملف ينفذ عناصر SideBar حسب مواصفات
/// PRODUCT_REDESIGN_MASTER_PLAN.md - القسم 3.2
/// 
/// آخر تحديث: 2026-07-09

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/custom_icons.dart';
import 'badge_widget.dart';

/// نموذج بيانات لعنصر SideBar
class SidebarItemModel {
  /// المعرف الفريد
  final String id;
  
  /// الاسم الذي يظهر في SideBar
  final String label;
  
  /// الأيقونة
  final IconData icon;
  
  /// المسار (Route)
  final String route;
  
  /// عدد Badge (0 يعني لا يظهر)
  final int badgeCount;
  
  /// نوع Badge
  final BadgeType badgeType;
  
  /// هل هذا العنصر مخفي
  final bool isHidden;
  
  /// هل هذا العنصر معطل
  final bool isDisabled;
  
  /// أداة مساعدة (Tooltip)
  final String? tooltip;
  
  /// العنصر الفرعي (إذا كان هناك قائمة منبثقة)
  final List<SidebarItemModel>? children;
  
  const SidebarItemModel({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.badgeCount = 0,
    this.badgeType = BadgeType.normal,
    this.isHidden = false,
    this.isDisabled = false,
    this.tooltip,
    this.children,
  });
  
  /// تحويل إلى widget
  Widget toWidget({
    required BuildContext context,
    required bool isExpanded,
    required String? selectedRoute,
    required void Function(SidebarItemModel) onItemSelected,
  }) {
    return SidebarItem(
      item: this,
      isExpanded: isExpanded,
      selectedRoute: selectedRoute,
      onSelected: onItemSelected,
    );
  }
}

/// widget لعنصر SideBar واحد
class SidebarItem extends StatelessWidget {
  /// نموذج البيانات
  final SidebarItemModel item;
  
  /// هل SideBar موسع
  final bool isExpanded;
  
  /// المسار المختار حاليا
  final String? selectedRoute;
  
  /// دالة عند اختيار العنصر
  final void Function(SidebarItemModel) onSelected;
  
  const SidebarItem({
    super.key,
    required this.item,
    required this.isExpanded,
    required this.selectedRoute,
    required this.onSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    // إذا كان العنصر مخفياً
    if (item.isHidden) {
      return const SizedBox.shrink();
    }
    
    // تحديد إذا كان العنصر مختاراً
    final isSelected = selectedRoute == item.route;
    
    // تحديد إذا كان هناك أطفال
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    
    // لون خلفية العنصر
    Color backgroundColor = AppColors.sidebarBackground;
    if (isSelected) {
      backgroundColor = AppColors.sidebarSelected;
    } else if (hasChildren) {
      // يمكن إضافة لون مختلف لعناصر القائمة
      backgroundColor = AppColors.sidebarBackground;
    }
    
    // لون النص
    Color textColor = isSelected 
        ? AppColors.sidebarTextSelected 
        : AppColors.sidebarText;
    
    // لون الأيقونة
    Color iconColor = isSelected 
        ? AppColors.sidebarIconSelected 
        : AppColors.sidebarIcon;
    
    // حجم العنصر
    final double itemHeight = 48.0;
    
    return Tooltip(
      message: item.tooltip ?? item.label,
      child: InkWell(
        onTap: item.isDisabled ? null : () => onSelected(item),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // الأيقونة
              Icon(
                item.icon,
                color: iconColor,
                size: 22,
              ),
              
              // المساحة بين الأيقونة والنص
              const SizedBox(width: 12),
              
              // النص (يظهر فقط عند التوسعة)
              if (isExpanded) ...[
                Expanded(
                  child: Text(
                    item.label,
                    style: isSelected 
                        ? AppTextStyles.sidebarItemSelected 
                        : AppTextStyles.sidebarItem,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Badge (يظهر فقط عند التوسعة)
                if (item.badgeCount > 0) ...[
                  const SizedBox(width: 8),
                  BadgeWidget(
                    count: item.badgeCount,
                    type: item.badgeType,
                    size: 20,
                  ),
                ],
              ] else ...[
                // Badge (يظهر عند الطي)
                if (item.badgeCount > 0) ...[
                  const SizedBox(width: 4),
                  BadgeWidget(
                    count: item.badgeCount,
                    type: item.badgeType,
                    size: 18,
                  ),
                ],
              ],
              
              // سهم إذا كان هناك أطفال (يظهر فقط عند التوسعة)
              if (isExpanded && hasChildren) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: iconColor,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// قائمة من عناصر SideBar
class SidebarItemList extends StatelessWidget {
  /// قائمة العناصر
  final List<SidebarItemModel> items;
  
  /// هل SideBar موسع
  final bool isExpanded;
  
  /// المسار المختار حاليا
  final String? selectedRoute;
  
  /// دالة عند اختيار العنصر
  final void Function(SidebarItemModel) onItemSelected;
  
  const SidebarItemList({
    super.key,
    required this.items,
    required this.isExpanded,
    required this.selectedRoute,
    required this.onItemSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        // إذا كان هناك أطفال، ننشئ قائمة منبثقة
        if (item.children != null && item.children!.isNotEmpty) {
          return _buildExpandableItem(context, item);
        }
        
        return item.toWidget(
          context: context,
          isExpanded: isExpanded,
          selectedRoute: selectedRoute,
          onItemSelected: onItemSelected,
        );
      }).toList(),
    );
  }
  
  Widget _buildExpandableItem(BuildContext context, SidebarItemModel parent) {
    // هذا يمكن تطويره لاحقاً للدعم الكامل للقوائم المنبثقة
    // حالياً، نعرض العنصر الرئيسي فقط
    return parent.toWidget(
      context: context,
      isExpanded: isExpanded,
      selectedRoute: selectedRoute,
      onItemSelected: onItemSelected,
    );
  }
}
