import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jiyibi_app/main.dart';
import 'package:jiyibi_app/services/category_provider.dart';
import 'package:jiyibi_app/services/storage_service.dart';
import 'package:jiyibi_app/services/transaction_provider.dart';

void main() {
  testWidgets('默认首页为记账页', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService(await SharedPreferences.getInstance());
    final transactions = TransactionProvider(storage);
    final categories = CategoryProvider(storage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: categories),
          ChangeNotifierProvider.value(value: transactions),
        ],
        child: const JiYiBiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 默认进入「记一笔」页面
    expect(find.text('记一笔'), findsWidgets);
    // 备注输入框存在
    expect(find.byType(TextField), findsOneWidget);
    // 内置 6 分类（含交通）
    expect(categories.categories.length, 6);
    expect(categories.byId('transport').name, '交通');
  });
}
