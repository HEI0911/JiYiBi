import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/category_provider.dart';
import '../services/transaction_provider.dart';

/// 最近记录页面 - 根据日期展示
class RecentRecordsPage extends StatelessWidget {
  const RecentRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TransactionProvider>();
    final grouped = provider.groupByDate(limit: 100);
    final dates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('最近记录',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('共 ${provider.records.length} 条账单',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            '总支出 ¥${provider.totalOf(provider.records).toStringAsFixed(2)}',
                            style: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: dates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('还没有账单',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: dates.length,
                      itemBuilder: (ctx, i) {
                        final date = dates[i];
                        final list = grouped[date]!;
                        final dayTotal = provider.totalOf(list);
                        final dateTime = DateTime.parse(date);
                        final weekday =
                            ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][
                                dateTime.weekday - 1];
                        final isToday =
                            DateUtils.isSameDay(dateTime, DateTime.now());
                        return _DateSection(
                          label: isToday
                              ? '今天 · $weekday'
                              : '${dateTime.month}月${dateTime.day}日 · $weekday',
                          total: dayTotal,
                          records: list,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final String label;
  final double total;
  final List records;

  const _DateSection({
    required this.label,
    required this.total,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant)),
                Text('当日 ¥${total.toStringAsFixed(2)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < records.length; i++) ...[
                  _RecordRow(record: records[i]),
                  if (i != records.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 68),
                      child: Divider(height: 1),
                    ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatefulWidget {
  final dynamic record;
  const _RecordRow({required this.record});

  @override
  State<_RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<_RecordRow> {
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.record;
    final cat = context.watch<CategoryProvider>().byId(r.categoryId);
    final time = DateFormat('HH:mm').format(r.createdAt);

    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: theme.colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        setState(() => _confirming = true);
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除记录'),
            content: Text('确认删除 ¥${r.amount.toStringAsFixed(2)} 的${cat.name}记录？'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError),
                  child: const Text('删除')),
            ],
          ),
        );
        setState(() => _confirming = false);
        return ok == true;
      },
      onDismissed: (_) {
        context.read<TransactionProvider>().remove(r.id);
      },
      child: _confirming
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icon, color: cat.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          r.note?.isNotEmpty == true
                              ? '${r.note!} · $time'
                              : time,
                          // 分类名（titleSmall w600，≈14）和 备注/时间 看起来尺寸相当时，
                          // 把次级信息降到 bodySmall 下一级显式 fontSize 11.5，
                          // 让分类名更突出，层级更清晰。
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11.5,
                                height: 1.1,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text('-¥${r.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface)),
                ],
              ),
            ),
    );
  }
}
