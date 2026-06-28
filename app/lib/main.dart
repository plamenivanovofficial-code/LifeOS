import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/local_db.dart';
import 'data/repository.dart';
import 'data/sync_service.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('bg');
  await LocalDb.open();

  final sync = SyncService();
  final repo = Repository(sync);
  sync.syncNow(); // първоначална синхронизация

  runApp(NorthApp(repo: repo, sync: sync));
}

class NorthApp extends StatefulWidget {
  final Repository repo;
  final SyncService sync;
  const NorthApp({super.key, required this.repo, required this.sync});

  @override
  State<NorthApp> createState() => _NorthAppState();
}

class _NorthAppState extends State<NorthApp> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // тих опит за синхронизация на всеки 15 секунди
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => widget.sync.syncNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.sync.syncNow();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NorthOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: null),
      home: HomeScreen(repo: widget.repo),
    );
  }
}
