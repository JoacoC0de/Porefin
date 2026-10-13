import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final String type;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.sortOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': AppTheme.hexFromColor(color),
      'type': type,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: AppTheme.colorFromHex(map['color'] as String),
      type: map['type'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}