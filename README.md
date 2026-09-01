# 记一笔 (JiYiBi)

<p align="center">
  <img src="docs/icon.png" width="96" alt="应用图标" />
</p>

极简 Android 记账应用——打开即记，三秒完成一笔账。无登录、无广告、无网络请求。

## 功能

- **极速记账**：输金额、点分类即存；默认当前时间，支持回溯修改；可添加备注
- **自定义分类**：自由添加新分类，长按拖动排序；展开「更多」可管理常用/扩展分类视图
- **最近记录**：账单按日期分组浏览，左滑删除
- **汇总排行**：本月 / 上月 / 本年 / 全部 / 自定义时间范围，各分类支出总额与占比；附饼图、分类横向占比排行、单笔金额排行（支持分类筛选）
- **纯本地存储**：所有数据只存在你的手机里
- **夜间模式**：跟随系统深浅色自动切换，启动图标同步反转

## 下载

从 [Releases](../../releases) 获取安装包，命名格式为 `jiyibi-app-v版本号.apk`，例如 `jiyibi-app-v1.0.0.apk`（Android 5.0+）。该命名由 GitHub Actions 自动构建时重命名，本地手动构建产物为标准的 `app-release.apk`（见「构建」章节）。安装时若系统提示"未知来源应用"，允许即可。

## 数据与隐私

- 不申请网络权限，账单不上传、不同步
- 不收集任何个人信息，无第三方统计与广告 SDK
- 卸载应用即清除全部数据，重要账单请自行备份

## 免责声明

> 本软件按"现状"提供，不附带任何明示或默示的担保。在适用法律允许的最大范围内，作者不对因使用或无法使用本软件而产生的任何直接或间接损失承担责任。
>
> 账单数据仅存储于设备本地，卸载应用、清除应用数据或设备故障都可能导致数据永久丢失，请自行做好备份。统计与图表结果仅作个人记账参考，不构成任何财务建议。

---

## 技术栈

- [Flutter](https://flutter.dev) / Dart（Material 3）
- [provider](https://pub.dev/packages/provider) — 状态管理
- [shared_preferences](https://pub.dev/packages/shared_preferences) — 本地存储
- [fl_chart](https://pub.dev/packages/fl_chart) — 饼图 / 柱状图
- [intl](https://pub.dev/packages/intl) / [uuid](https://pub.dev/packages/uuid)
- [得意黑 Smiley Sans](https://github.com/atelier-anchor/smiley-sans) — 字体（SIL OFL 1.1，见 `assets/fonts/`）

## 构建

```bash
flutter pub get
flutter build apk --release
```

产物位于 `build/app/outputs/flutter-apk/app-release.apk`。

> **关于文件名**：Flutter 本地构建统一输出 `app-release.apk`（debug 构建对应 `app-debug.apk`）。
> 通过 GitHub Actions 发布 Release 时，CI 会把产物重命名为 `jiyibi-app-v版本号.apk`（例如 `jiyibi-app-v1.0.0.apk`）。
> 如果你希望本地构建也用同样的名字，构建后执行：
> ```bash
> cp build/app/outputs/flutter-apk/app-release.apk "jiyibi-app-v1.0.0.apk"
> ```

## 目录结构

```
lib/
├── main.dart                        # 入口：主题、本地化、底部导航
├── models/
│   ├── category.dart                # 分类模型（内置分类 + 自定义）
│   └── transaction.dart             # 账单模型与序列化
├── services/
│   ├── storage_service.dart         # shared_preferences 持久化
│   ├── category_provider.dart       # 分类状态（自定义、排序、显示管理）
│   └── transaction_provider.dart    # 账单状态（增删查、分组、聚合）
└── pages/
    ├── add_record_page.dart         # 记账页（首页）
    ├── recent_records_page.dart     # 最近记录
    └── summary_page.dart            # 汇总排行
```

## 许可

本项目代码采用 [MIT License](LICENSE) 发布。

第三方依赖均使用宽松开源许可（MIT / BSD-3 / Apache-2.0），Material 图标由 Flutter SDK 随附（Apache-2.0）。
