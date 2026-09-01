import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import 'storage_service.dart';

class TransactionProvider extends ChangeNotifier {
  final StorageService _storage;
  List<TransactionRecord> _records = [];
  static const Uuid _uuid = Uuid();

  TransactionProvider(this._storage) {
    _records = _storage.loadTransactions();
  }

  List<TransactionRecord> get records => List.unmodifiable(_records);

  /// 最近 N 条记录（按时间倒序）
  List<TransactionRecord> recent({int limit = 50}) {
    final sorted = List<TransactionRecord>.from(_records)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  /// 按日期分组（最近记录）
  Map<String, List<TransactionRecord>> groupByDate({int? limit}) {
    final source = limit != null ? recent(limit: limit) : recent();
    final Map<String, List<TransactionRecord>> result = {};
    for (final r in source) {
      final key =
          '${r.createdAt.year.toString().padLeft(4, '0')}-${r.createdAt.month.toString().padLeft(2, '0')}-${r.createdAt.day.toString().padLeft(2, '0')}';
      result.putIfAbsent(key, () => []).add(r);
    }
    return result;
  }

  /// 某时间段内记录
  List<TransactionRecord> inRange(DateTime start, DateTime end) {
    return _records.where((r) {
      final t = r.createdAt;
      return !t.isBefore(start) && t.isBefore(end);
    }).toList();
  }

  /// 按分类聚合（返回 Map<categoryId, totalAmount>）
  Map<String, double> sumByCategory(List<TransactionRecord> list) {
    final Map<String, double> result = {};
    for (final r in list) {
      result[r.categoryId] = (result[r.categoryId] ?? 0) + r.amount;
    }
    return result;
  }

  double totalOf(List<TransactionRecord> list) {
    return list.fold<double>(0, (sum, r) => sum + r.amount);
  }

  /// 新增一笔记录
  /// [createdAt] 可指定记账时间（默认此刻），用于忘记记账后的候补
  Future<void> add({
    required double amount,
    required String categoryId,
    String? note,
    DateTime? createdAt,
  }) async {
    final trimmedNote = note?.trim();
    final record = TransactionRecord(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      createdAt: createdAt ?? DateTime.now(),
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
    );
    _records.insert(0, record);
    notifyListeners();
    await _storage.addTransaction(record);
  }

  Future<void> remove(String id) async {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
    await _storage.removeTransaction(id);
  }
}
