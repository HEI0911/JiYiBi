import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/category_provider.dart';
import '../services/transaction_provider.dart';

/// 汇总排行页面
/// 功能：
///   - 时段切换（本月/上月/本年/全部/自定义）
///   - 各分类支出总额 + 占比排行
///   - 饼图 + 横向占比条 可视化
class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

enum _Period { thisMonth, lastMonth, year, all, custom }

class _SummaryPageState extends State<SummaryPage> {
  _Period _period = _Period.thisMonth;
  DateTimeRange? _customRange;
  /// 条目排行过滤：null 代表「全部」，非 null 代表只看该分类下的条目
  String? _entryFilterCatId;

  static const Map<_Period, String> _periodNames = {
    _Period.thisMonth: '本月',
    _Period.lastMonth: '上月',
    _Period.year: '本年',
    _Period.all: '全部',
    _Period.custom: '自定义',
  };

  DateTimeRange _rangeFor(_Period p) {
    final now = DateTime.now();
    switch (p) {
      case _Period.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return DateTimeRange(start: start, end: end);
      case _Period.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: end);
      case _Period.year:
        return DateTimeRange(
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year + 1, 1, 1));
      case _Period.all:
        return DateTimeRange(
            start: DateTime(2000), end: DateTime(2099, 12, 31));
      case _Period.custom:
        final start =
            _customRange?.start ?? DateTime(now.year, now.month, 1);
        final end = (_customRange?.end ?? now).add(const Duration(days: 1));
        return DateTimeRange(start: start, end: end);
    }
  }

  Future<void> _selectPeriod(_Period p) async {
    if (p == _Period.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange: _customRange ??
            DateTimeRange(
                start: DateTime(now.year, now.month, 1), end: now),
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year, now.month, now.day),
      );
      if (picked == null) return;
      _customRange = picked;
    }
    setState(() => _period = p);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TransactionProvider>();
    final cats = context.watch<CategoryProvider>().categories;
    final range = _rangeFor(_period);
    final list = provider.inRange(range.start, range.end);
    final total = provider.totalOf(list);
    final sumByCat = provider.sumByCategory(list);

    // 构造分类排行（只保留该时段内实际有条目的分类，按金额从高到低）
    final rankings = cats
        .map((c) => MapEntry(c, sumByCat[c.id] ?? 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('汇总',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

            // 时段切换：5 个按钮均分一行铺满面宽度，
            // 外左右 padding 20 与下方总计卡对齐。
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                // 外层 SizedBox 锁定行高，避免 Expanded 在无垂直约束下被拉伸。
                child: SizedBox(
                  height: 40,
                  child: Builder(
                    builder: (ctx) {
                      final periodList = _Period.values.toList();
                      return Row(
                        children: [
                          for (int i = 0; i < periodList.length; i++) ...[
                            Expanded(
                              child: _PeriodButton(
                                label: _periodNames[periodList[i]]!,
                                selected: _period == periodList[i],
                                onTap: () => _selectPeriod(periodList[i]),
                              ),
                            ),
                            if (i != periodList.length - 1)
                              const SizedBox(width: 8),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // 总支出卡片
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_periodLabel(),
                                style: TextStyle(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text('¥${total.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineMedium
                                    ?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text('共 ${list.length} 笔支出',
                                style: TextStyle(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.8),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.pie_chart_rounded,
                            size: 36, color: theme.colorScheme.onPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 饼图
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('支出占比（饼图）',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: total == 0
                              ? _buildEmpty(context)
                              : PieChart(PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 48,
                                  sections: _buildPieSections(rankings),
                                )),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: rankings
                              .map((e) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                              color: e.key.color,
                                              shape: BoxShape.circle)),
                                      const SizedBox(width: 4),
                                      Text(
                                          '${e.key.name} ${(total == 0 ? 0 : (e.value / total * 100)).toStringAsFixed(1)}%',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                  fontSize: 14,
                                                  letterSpacing: 1.0)),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 横向占比排行（按分类总支出排序）
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: rankings.isEmpty
                        ? SizedBox(
                            height: 120,
                            child: _buildEmpty(context),
                          )
                        : Column(
                            children: [
                              for (int i = 0; i < rankings.length; i++)
                                _RankRow(
                                  rank: i + 1,
                                  category: rankings[i].key,
                                  amount: rankings[i].value,
                                  total: total,
                                ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            // 条目排行：按单笔金额降序，支持按分类筛选
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Builder(
                      builder: (ctx) {
                        // 只取当前时段内实际有账单的分类，用作筛选器
                        final catList = <CategoryModel>[
                          for (final e in rankings) e.key,
                        ];
                        // 筛选：null（全部）或匹配某个分类 id
                        final filtered = list.where((r) {
                          final cid = _entryFilterCatId;
                          if (cid == null) return true;
                          return r.categoryId == cid;
                        }).toList();
                        // 单笔条目按金额从高到低排序
                        filtered.sort(
                            (a, b) => b.amount.compareTo(a.amount));
                        final byId = {
                          for (final c in cats) c.id: c,
                        };
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('单笔金额排行',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700)),
                                ),
                                Text('${filtered.length} 笔',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // 分类筛选 Chips（全部 + 该时段内有数据的分类）
                            SizedBox(
                              width: double.infinity,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: const Text('全部'),
                                        selected: _entryFilterCatId == null,
                                        showCheckmark: false,
                                        onSelected: (_) => setState(
                                            () => _entryFilterCatId = null),
                                      ),
                                    ),
                                    for (final c in catList)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: ChoiceChip(
                                          label: Text(c.name),
                                          selected:
                                              _entryFilterCatId == c.id,
                                          showCheckmark: false,
                                          avatar: Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: c.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          onSelected: (_) => setState(() =>
                                              _entryFilterCatId = c.id),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (filtered.isEmpty)
                              SizedBox(height: 120, child: _buildEmpty(ctx))
                            else
                              Column(
                                children: [
                                  for (int i = 0;
                                      i < filtered.length;
                                      i++) ...[
                                    if (i > 0)
                                      const Divider(height: 1, thickness: 1),
                                    _EntryRankTile(
                                      rank: i + 1,
                                      record: filtered[i],
                                      category: byId[filtered[i].categoryId],
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.thisMonth:
        return '${now.year} 年 ${now.month} 月支出总计';
      case _Period.lastMonth:
        final m = now.month - 1 == 0 ? 12 : now.month - 1;
        final y = now.month - 1 == 0 ? now.year - 1 : now.year;
        return '$y 年 $m 月支出总计';
      case _Period.year:
        return '${now.year} 年支出总计';
      case _Period.custom:
        final r = _customRange;
        if (r == null) return '自定义时段支出总计';
        return '${r.start.year}.${r.start.month}.${r.start.day} - ${r.end.month}.${r.end.day} 支出总计';
      case _Period.all:
        return '全部时间支出总计';
    }
  }

  List<PieChartSectionData> _buildPieSections(
      List<MapEntry<CategoryModel, double>> list) {
    final total = list.fold<double>(0, (s, e) => s + e.value);
    if (total == 0) return [];
    return list.map((e) {
      final percent = e.value / total;
      return PieChartSectionData(
        color: e.key.color,
        value: e.value,
        title: '${(percent * 100).toStringAsFixed(0)}%',
        radius: 58,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 40,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text('此时间段暂无数据',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final CategoryModel category;
  final double amount;
  final double total;

  const _RankRow({
    required this.rank,
    required this.category,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = total == 0 ? 0.0 : amount / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$rank',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: rank <= 3
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(category.icon, color: category.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('¥${amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(category.color),
                  ),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${(percent * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 单笔条目排行的一行（按金额从高到低序号）
/// 左：排名 + 分类图标色块
/// 中：分类名 · 备注 / 日期时间
/// 右：金额
class _EntryRankTile extends StatelessWidget {
  final int rank;
  final TransactionRecord record;
  final CategoryModel? category;

  const _EntryRankTile({
    required this.rank,
    required this.record,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = category;
    final catColor = cat?.color ?? theme.colorScheme.primary;
    final catIcon = cat?.icon ?? Icons.category_rounded;

    final date = record.createdAt;
    final dateStr =
        '${date.month}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final title =
        cat?.name ?? '已删除分类';
    final subtitle = (record.note == null || record.note!.isEmpty)
        ? dateStr
        : '$dateStr  ·  ${record.note!}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('$rank',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: rank <= 3
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(catIcon, color: catColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11.5,
                        height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('¥${record.amount.toStringAsFixed(2)}',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// 汇总页顶部的「时段选择按钮」（本月/上月/本年/全部/自定义）。
/// 不使用 Flutter 的 ChoiceChip：ChoiceChip 内部有固定 intrinsicWidth，
/// 当一行塞 5 个时容易溢出横滑，视觉上和下方总计卡的右边界对不齐。
/// 这个按钮撑满传入的宽度（配合 Expanded 均分一行），
/// 所以整排左/右外边界 = 总计卡左/右外边界，像素级对齐。
class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final fg = selected
        ? theme.colorScheme.primary
        : theme.chipTheme.labelStyle?.color ?? theme.colorScheme.onSurface;

    return Material(
      color: bg,
      // Material 的 shape 和 borderRadius 不能同时指定；
      // 这里统一通过 shape 给圆角 + 边框
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
            color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        // InkWell 自己的波纹圆角要跟 shape 一致
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Smiley Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: fg,
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
