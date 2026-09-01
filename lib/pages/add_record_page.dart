import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../services/category_provider.dart';
import '../services/transaction_provider.dart';

/// 记账页面 - 默认首页
/// 金额数字键盘 + 分类选择（可拖动排序/自定义） + 可选备注 + 可选记账时间
class AddRecordPage extends StatefulWidget {
  const AddRecordPage({super.key});

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  final TextEditingController _noteController = TextEditingController();
  DateTime _recordTime = DateTime.now();
  String _amountStr = '';
  String? _selectedCategoryId;
  // 分类默认只展示前 3 个，其余收起，可展开
  bool _categoriesExpanded = false;
  // 用户是否手动修改过记账时间（改过则后台恢复时不自动刷新为当前时间）
  bool _timeTouched = false;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // 冷启动时也把时间重置成「此刻」（避免取的是 Widget 创建时间，
    // 该时间可能比实际用户看到页面的时间早）
    _recordTime = DateTime.now();
    // 监听应用生命周期：从后台切回前台时刷新时间
    // （使用 Flutter 3.13+ 的 AppLifecycleListener，避免旧接口
    //  WidgetsBindingObserver.didChangeAppLifecycleState 在新版本中不触发）
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (!_timeTouched && mounted) {
          setState(() => _recordTime = DateTime.now());
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _appendDigit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (d == '.' && _amountStr.contains('.')) return;
      if (_amountStr.isEmpty && d == '.') {
        _amountStr = '0.';
        return;
      }
      // 限制小数两位
      if (_amountStr.contains('.')) {
        final parts = _amountStr.split('.');
        if (parts.length == 2 && parts[1].length >= 2) return;
      }
      if (_amountStr == '0' && d != '.') {
        _amountStr = d;
      } else {
        _amountStr += d;
      }
    });
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountStr.isEmpty) return;
      _amountStr = _amountStr.substring(0, _amountStr.length - 1);
    });
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _amountStr = '';
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordTime,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _timeTouched = true;
        _recordTime = DateTime(picked.year, picked.month, picked.day,
            _recordTime.hour, _recordTime.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordTime),
    );
    if (picked != null) {
      setState(() {
        _timeTouched = true;
        _recordTime = DateTime(_recordTime.year, _recordTime.month,
            _recordTime.day, picked.hour, picked.minute);
      });
    }
  }

  /// 日期文本：
  ///  - 数字与「年/月/日」汉字之间加全角空格，视觉上不挤；
  ///  - 日期与星期之间用半角空格留一个间隙。
  String _dateLabel(DateTime t) {
    final now = DateTime.now();
    final wd = const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][t.weekday - 1];
    final date = t.year == now.year
        ? '${t.month} 月 ${t.day} 日'
        : '${t.year} 年 ${t.month} 月 ${t.day} 日';
    return '$date  $wd';
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _showManageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ManageCategoriesSheet(),
    );
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入有效的金额')));
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请选择一个分类')));
      return;
    }
    final provider = context.read<TransactionProvider>();
    final categoryName =
        context.read<CategoryProvider>().byId(_selectedCategoryId!).name;
    await provider.add(
      amount: amount,
      categoryId: _selectedCategoryId!,
      note: _noteController.text,
      createdAt: _recordTime,
    );
    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          content: Text('已记 ¥${amount.toStringAsFixed(2)} · $categoryName'),
        ),
      );
      setState(() {
        _amountStr = '';
        _noteController.clear();
        _recordTime = DateTime.now();
        _timeTouched = false;
        // 保留上一次分类方便快速连记
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayAmount = _amountStr.isEmpty ? '0' : _amountStr;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('记一笔',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),

              // 金额显示区
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                      theme.colorScheme.tertiary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text('支出金额',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        text: '¥ ',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(
                            text: displayAmount,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 分类选择（默认展示前 4 个，其余收进「更多」；自定义入口在展开区）
              Text('选择分类',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final cats = context.watch<CategoryProvider>().homeCategories;
                final hasMore = cats.length > 4;
                final shown =
                    _categoriesExpanded ? cats : cats.take(4).toList();
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    for (final c in shown)
                      _DraggableCategoryChip(
                        category: c,
                        selected: _selectedCategoryId == c.id,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategoryId = c.id);
                        },
                        onReorder: (dragId, targetId) =>
                            context.read<CategoryProvider>().reorder(
                                  dragId,
                                  targetId,
                                ),
                      ),
                    if (hasMore)
                      _ToggleMoreTile(
                        expanded: _categoriesExpanded,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _categoriesExpanded = !_categoriesExpanded;
                          });
                        },
                      ),
                    if (_categoriesExpanded)
                      _AddCategoryTile(onTap: _showManageSheet),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // 记账时间（默认此刻，可改选历史时间用于候补记账）
              Row(
                children: [
                  Expanded(
                    child: _PickerChip(
                      icon: Icons.calendar_today_rounded,
                      label: _dateLabel(_recordTime),
                      onTap: _pickDate,
                      // 用 letterSpacing+格式化空格，把日期整体填到"左右接近填满 Expanded"，
                      // 同时保持 TextAlign.center 居中（与左右 12px 内边距保持协调）。
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerChip(
                      icon: Icons.schedule_rounded,
                      label: _timeLabel(_recordTime),
                      onTap: _pickTime,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 备注（选填）
              // 与 _PickerChip 完全一致的外层盒模型与左侧 icon 间距，
              // 保证与日期/时间行图标、基线、高度、圆角完全对齐。
              Material(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 46,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                            child: TextField(
                              controller: _noteController,
                              maxLines: 1,
                              textInputAction: TextInputAction.done,
                              onTapOutside: (_) =>
                                  FocusManager.instance.primaryFocus
                                      ?.unfocus(),
                              textAlignVertical: TextAlignVertical.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                hintText: '备注',
                                hintStyle: theme.textTheme.titleSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.2,
                                        color: theme
                                            .colorScheme.onSurfaceVariant),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 数字键盘
              _buildKeypad(),
              const SizedBox(height: 16),

              // 记一笔按钮
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('记一笔',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];
    return Column(
      children: [
        for (int i = 0; i < keys.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (int j = 0; j < 3; j++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: j == 0 ? 0 : 6, right: j == 2 ? 0 : 6),
                      child: _KeyButton(
                        label: keys[i][j],
                        onTap: () {
                          final k = keys[i][j];
                          if (k == '⌫') {
                            _backspace();
                          } else {
                            _appendDigit(k);
                          }
                        },
                        onLongPress: keys[i][j] == '⌫' ? _clear : null,
                        isDelete: keys[i][j] == '⌫',
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DraggableCategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;
  final Future<void> Function(String dragId, String targetId) onReorder;

  const _DraggableCategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<CategoryModel>(
      data: category,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: const Offset(-42, -42),
        child: SizedBox(
          width: 84,
          height: 84,
          child: _CategoryChip(category: category, selected: true, onTap: () {}),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _CategoryChip(category: category, selected: false, onTap: () {}),
      ),
      child: DragTarget<CategoryModel>(
        onWillAcceptWithDetails: (details) =>
            details.data.id != category.id,
        onAcceptWithDetails: (details) =>
            onReorder(details.data.id, category.id),
        builder: (context, candidate, _) => _CategoryChip(
          category: category,
          selected: selected || candidate.isNotEmpty,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ToggleMoreTile extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _ToggleMoreTile({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 26,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(expanded ? '收起' : '更多',
                style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                size: 26, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text('自定义',
                style: TextStyle(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ManageCategoriesSheet extends StatefulWidget {
  const _ManageCategoriesSheet();

  @override
  State<_ManageCategoriesSheet> createState() => _ManageCategoriesSheetState();
}

class _ManageCategoriesSheetState extends State<_ManageCategoriesSheet> {
  final TextEditingController _nameController = TextEditingController();
  IconData _icon = CategoryList.iconChoices.first;
  Color _color = CategoryList.colorChoices.first;
  bool _showOnHome = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<CategoryProvider>();
    final all = provider.categories;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('自定义分类',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              maxLines: 1,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(
                hintText: '分类名称',
                counterText: '',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Text('图标',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in CategoryList.iconChoices)
                  _IconChoice(
                    icon: icon,
                    color: _color,
                    selected: _icon == icon,
                    onTap: () => setState(() => _icon = icon),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('颜色',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in CategoryList.colorChoices)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _color == color ? color : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: Icon(Icons.circle_rounded,
                          color: color, size: 18),
                    ),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('添加后在首页显示'),
              value: _showOnHome,
              onChanged: (v) => setState(() => _showOnHome = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  final messenger = ScaffoldMessenger.of(context);
                  if (name.isEmpty) {
                    messenger.showSnackBar(
                        const SnackBar(content: Text('请输入分类名称')));
                    return;
                  }
                  await context.read<CategoryProvider>().addCustom(
                        name,
                        _icon,
                        _color,
                        showOnHome: _showOnHome,
                      );
                  _nameController.clear();
                  messenger.showSnackBar(SnackBar(
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      content: Text('已添加分类「$name」')));
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('添加分类'),
              ),
            ),
            const SizedBox(height: 18),
            Text('分类显示管理',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('关闭开关可从首页隐藏该分类，已有账单与统计不受影响',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: theme.colorScheme.outlineVariant, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (final c in all)
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Icon(c.icon, color: c.color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(c.name,
                                style: theme.textTheme.bodyMedium),
                          ),
                          if (!provider.isBuiltIn(c.id))
                            IconButton(
                              tooltip: '移除分类',
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.delete_outline_rounded,
                                  size: 20,
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                              onPressed: () async {
                                final categoryProvider =
                                    context.read<CategoryProvider>();
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('移除分类'),
                                    content: Text(
                                        '确认移除「${c.name}」？已有账单记录会保留。'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('取消')),
                                      FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text('移除')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await categoryProvider
                                      .removeCustom(c.id);
                                }
                              },
                            ),
                          Switch(
                            value: !provider.isHidden(c.id),
                            onChanged: (show) => context
                                .read<CategoryProvider>()
                                .setHidden(c.id, !show),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          border: Border.all(
              color: selected
                  ? color
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            size: 22,
            color: selected ? color : theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.18)
              : theme.colorScheme.surface,
          border: Border.all(
              color: selected ? category.color : theme.dividerColor,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: category.color.withValues(alpha: 0.2), blurRadius: 8)
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon,
                color: selected ? category.color : theme.iconTheme.color,
                size: 26),
            const SizedBox(height: 4),
            Text(category.name,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? category.color
                        : theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _PickerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  /// 字间距（时间框希望字符间隔更大，类似电子表风格；日期框留 0 即可）
  final double letterSpacing;

  const _PickerChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  // FittedBox(scaleDown)：在当前文字超出可用宽度时自动缩放，
                  // 日常情况下按原尺寸显示，配合 letterSpacing 让日期文本更舒展。
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: letterSpacing,
                            )),
                  ),
                ),
                Icon(Icons.expand_more_rounded,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isDelete;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 52,
          child: Center(
            child: isDelete
                ? Icon(Icons.backspace_rounded,
                    color: theme.colorScheme.error, size: 24)
                : Text(label,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}
