import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_store.dart';

void main() {
  runApp(
    ChangeNotifierProvider<AppStore>(
      create: (_) => AppStore(),
      child: const ErpDemoApp(),
    ),
  );
}
