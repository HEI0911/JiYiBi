import 'package:flutter/material.dart';
import '../models/category.dart';
import 'storage_service.dart';

/// 分类状态：内置分类 + 用户自定义分类，顺序可拖动调整并持久化
class CategoryProvider extends ChangeNotifier {
  final StorageService _storage;
  List<CategoryModel> _categories = List.from(CategoryList.builtIn);
  Set<String> _hiddenIds = {};

  CategoryProvider(this._storage) {
    _load();
  }

  List<CategoryModel> get categories => List.unmodifiable(_categories);

  /// 首页展示的分类（不含被隐藏的）
  List<CategoryModel> get homeCategories =>
      List.unmodifiable(_categories.where((c) => !_hiddenIds.contains(c.id)));

  bool isHidden(String id) => _hiddenIds.contains(id);

  List<String> get _builtInIds =>
      CategoryList.builtIn.map((c) => c.id).toList();

  bool isBuiltIn(String id) => _builtInIds.contains(id);

  CategoryModel byId(String id) => _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => _categories.first,
      );

  /// 旧版内置顺序（住房在末位）。未自定义过顺序的老数据自动迁移为新顺序
  static const List<String> _legacyOrder = [
    'food',
    'shopping',
    'transport',
    'communication',
    'medical',
    'housing',
  ];

  void _load() {
    final customs = _storage
        .loadCustomCategories()
        .map((e) => CategoryModel.fromJson(e))
        .toList();
    _categories = [...CategoryList.builtIn, ...customs];

    final order = _migrateLegacyOrder(_storage.loadCategoryOrder());
    if (order.isNotEmpty) {
      final remaining = {for (final c in _categories) c.id: c};
      _categories = [
        for (final id in order)
          if (remaining.containsKey(id)) remaining.remove(id)!,
        ...remaining.values,
      ];
    }

    _hiddenIds = _storage
        .loadHiddenCategories()
        .where((id) => _categories.any((c) => c.id == id))
        .toSet();
  }

  /// 若存储顺序中内置 6 项的相对顺序仍与旧默认一致（用户未拖动过），
  /// 则替换为新默认顺序（住房提前），自定义分类相对位置不变
  List<String> _migrateLegacyOrder(List<String> order) {
    if (order.isEmpty) return order;
    final legacyPart =
        order.where(_legacyOrder.contains).toList();
    if (legacyPart.length != _legacyOrder.length) return order;
    for (var i = 0; i < _legacyOrder.length; i++) {
      if (legacyPart[i] != _legacyOrder[i]) return order;
    }
    final customs = order.where((id) => !_legacyOrder.contains(id)).toList();
    return [
      ...CategoryList.builtIn.map((c) => c.id),
      ...customs,
    ];
  }

  Future<void> _persist() async {
    await _storage.saveCustomCategories(_categories
        .where((c) => !isBuiltIn(c.id))
        .map((c) => c.toJson())
        .toList());
    await _storage.saveCategoryOrder(_categories.map((c) => c.id).toList());
    await _storage.saveHiddenCategories(_hiddenIds.toList());
  }

  /// 设置分类是否在首页显示（隐藏后已有账单与统计不受影响）
  Future<void> setHidden(String id, bool hidden) async {
    if (hidden) {
      _hiddenIds.add(id);
    } else {
      _hiddenIds.remove(id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> addCustom(String name, IconData icon, Color color,
      {bool showOnHome = true}) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    _categories = [
      ..._categories,
      CategoryModel(id: id, name: name, icon: icon, color: color),
    ];
    if (!showOnHome) _hiddenIds.add(id);
    notifyListeners();
    await _persist();
  }

  Future<void> removeCustom(String id) async {
    if (isBuiltIn(id)) return;
    _categories = _categories.where((c) => c.id != id).toList();
    _hiddenIds.remove(id);
    notifyListeners();
    await _persist();
  }

  /// 长按拖动排序：把 [dragId] 移动到 [targetId] 所在位置（插入式）
  Future<void> reorder(String dragId, String targetId) async {
    if (dragId == targetId) return;
    final from = _categories.indexWhere((c) => c.id == dragId);
    final to = _categories.indexWhere((c) => c.id == targetId);
    if (from < 0 || to < 0) return;
    final item = _categories.removeAt(from);
    _categories.insert(to, item);
    notifyListeners();
    await _persist();
  }
}
