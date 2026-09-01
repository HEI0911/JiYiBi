import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class StorageService {
  static const String _kTransactions = 'transactions_v1';
  static const String _kCustomCategories = 'custom_categories_v1';
  static const String _kCategoryOrder = 'category_order_v1';
  static const String _kHiddenCategories = 'hidden_categories_v1';
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ---------- 账单 ----------

  List<TransactionRecord> loadTransactions() {
    final raw = _prefs.getString(_kTransactions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TransactionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionRecord> list) async {
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_kTransactions, raw);
  }

  Future<void> addTransaction(TransactionRecord record) async {
    final list = loadTransactions();
    list.insert(0, record);
    await saveTransactions(list);
  }

  Future<void> removeTransaction(String id) async {
    final list = loadTransactions()..removeWhere((e) => e.id == id);
    await saveTransactions(list);
  }

  // ---------- 分类（自定义 + 顺序） ----------

  List<Map<String, dynamic>> loadCustomCategories() {
    final raw = _prefs.getString(_kCustomCategories);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomCategories(List<Map<String, dynamic>> list) async {
    await _prefs.setString(_kCustomCategories, jsonEncode(list));
  }

  List<String> loadCategoryOrder() {
    final raw = _prefs.getString(_kCategoryOrder);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCategoryOrder(List<String> ids) async {
    await _prefs.setString(_kCategoryOrder, jsonEncode(ids));
  }

  List<String> loadHiddenCategories() {
    final raw = _prefs.getString(_kHiddenCategories);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHiddenCategories(List<String> ids) async {
    await _prefs.setString(_kHiddenCategories, jsonEncode(ids));
  }
}
