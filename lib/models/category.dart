import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon.codePoint,
        'color': color.toARGB32(),
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final codePoint = json['icon'] as int;
    // 从 const 图标列表中回查，避免非 const IconData 破坏图标树摇
    final known = {
      ...CategoryList.builtIn.map((c) => c.icon),
      ...CategoryList.iconChoices,
    }.where((i) => i.codePoint == codePoint);
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: known.isEmpty ? Icons.category_rounded : known.first,
      color: Color(json['color'] as int),
    );
  }
}

class CategoryList {
  /// 内置分类：餐饮、购物、交通、住房、通讯、医疗
  static const List<CategoryModel> builtIn = [
    CategoryModel(
      id: 'food',
      name: '餐饮',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE57373),
    ),
    CategoryModel(
      id: 'shopping',
      name: '购物',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF64B5F6),
    ),
    CategoryModel(
      id: 'transport',
      name: '交通',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF4DD0E1),
    ),
    CategoryModel(
      id: 'housing',
      name: '住房',
      icon: Icons.home_rounded,
      color: Color(0xFFBA68C8),
    ),
    CategoryModel(
      id: 'communication',
      name: '通讯',
      icon: Icons.phone_android_rounded,
      color: Color(0xFFFFB74D),
    ),
    CategoryModel(
      id: 'medical',
      name: '医疗',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFF81C784),
    ),
  ];

  /// 自定义分类可选图标（与内置风格统一：rounded 圆角线性图标）
  static const List<IconData> iconChoices = [
    Icons.directions_subway_rounded,
    Icons.flight_takeoff_rounded,
    Icons.two_wheeler_rounded,
    Icons.local_cafe_rounded,
    Icons.checkroom_rounded,
    Icons.pets_rounded,
    Icons.fitness_center_rounded,
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.school_rounded,
    Icons.savings_rounded,
    Icons.celebration_rounded,
  ];

  /// 自定义分类可选颜色（与内置同风格：Material 300 系淡彩）
  static const List<Color> colorChoices = [
    Color(0xFF4DD0E1),
    Color(0xFFF06292),
    Color(0xFFAED581),
    Color(0xFFFFD54F),
    Color(0xFF9575CD),
    Color(0xFF4DB6AC),
    Color(0xFFA1887F),
    Color(0xFF7986CB),
  ];
}
