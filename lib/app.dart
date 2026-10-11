import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_store.dart';
import 'features/import/import_screen.dart';
import 'features/sales_report/sales_screen.dart';
import 'features/stock/stock_screen.dart';

/// The single accent colour of the app: dark green.
const Color accentColor = Color(0xFF1B5E3F);

/// Below this width the layout scrolls sideways instead of squeezing.
const double minComfortableWidth = 1200;

class ErpDemoApp extends StatelessWidget {
  const ErpDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: accentColor).copyWith(
      primary: accentColor,
      surface: Colors.white,
    );
    return MaterialApp(
      title: 'Jewelry ERP Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF6F7F6),
        visualDensity: VisualDensity.compact,
        dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, width: 520),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navIndex = context.select<AppStore, int>((s) => s.navIndex);

    final shell = Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 52,
        titleSpacing: 16,
        shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        title: Row(
          children: <Widget>[
            Icon(Icons.diamond_outlined, color: scheme.primary),
            const SizedBox(width: 10),
            Text(
              'Jewelry ERP Demo',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Demo data',
                style: TextStyle(fontSize: 12, color: Color(0xFF5F5F5F)),
              ),
            ),
          ],
        ),
      ),
      body: Row(
        children: <Widget>[
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: navIndex,
            labelType: NavigationRailLabelType.all,
            minWidth: 96,
            onDestinationSelected: context.read<AppStore>().setNavIndex,
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Stock'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: Text('Sales Report'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.upload_file_outlined),
                selectedIcon: Icon(Icons.upload_file),
                label: Text('Import from\nExcel', textAlign: TextAlign.center),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            // Screens stay alive so filters and column layout survive
            // switching between them.
            child: IndexedStack(
              index: navIndex,
              sizing: StackFit.expand,
              children: const <Widget>[
                StockScreen(),
                SalesScreen(),
                ImportScreen(),
              ],
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= minComfortableWidth) return shell;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minComfortableWidth,
            height: constraints.maxHeight,
            child: shell,
          ),
        );
      },
    );
  }
}
