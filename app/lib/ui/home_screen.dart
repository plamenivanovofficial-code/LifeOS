import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/memory.dart';
import '../data/repository.dart';

class HomeScreen extends StatefulWidget {
  final Repository repo;
  const HomeScreen({super.key, required this.repo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Будна нощ.';
    if (h < 12) return 'Добро утро.';
    if (h < 18) return 'Добър ден.';
    return 'Добра вечер.';
  }

  void _submit() {
    final t = _controller.text;
    if (t.trim().isEmpty) return;
    widget.repo.capture(t);
    _controller.clear();
    _focus.requestFocus();
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final x = d.toLocal();
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final y = now.subtract(const Duration(days: 1));
    if (same(x, now)) return 'Днес';
    if (same(x, y)) return 'Вчера';
    return DateFormat('d MMMM', 'bg').format(x);
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF272D2A);
    const muted = Color(0xFF8B948D);
    const faint = Color(0xFFA9B1AB);
    const accent = Color(0xFF5E7D6E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(_greeting(),
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w500, color: ink)),
                  const SizedBox(height: 6),
                  const Text('Изсипи каквото ти е в главата. После не мисли за него.',
                      style: TextStyle(fontSize: 15, color: muted)),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x14272D2A)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0D272D2A),
                            blurRadius: 24,
                            offset: Offset(0, 8)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      maxLines: null,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(fontSize: 17, color: ink),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Какво ти е наум?',
                        hintStyle: TextStyle(color: faint),
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(child: _timeline(ink, muted, faint, accent)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeline(Color ink, Color muted, Color faint, Color accent) {
    return StreamBuilder<List<Memory>>(
      stream: widget.repo.watch(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Text('Тук е тихо.\nПървата мисъл върви в полето горе.',
                textAlign: TextAlign.center,
                style: TextStyle(color: faint, fontSize: 15, height: 1.6)),
          );
        }
        // групиране по ден
        final widgets = <Widget>[];
        String? lastDay;
        for (final m in items) {
          final dl = _dayLabel(m.createdAt);
          if (dl != lastDay) {
            widgets.add(Padding(
              padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
              child: Row(children: [
                Text(dl.toUpperCase(),
                    style: TextStyle(
                        color: muted, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 1, color: const Color(0x14272D2A))),
              ]),
            ));
            lastDay = dl;
          }
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 7, height: 7,
                margin: const EdgeInsets.only(top: 7, right: 7),
                decoration: BoxDecoration(
                    color: m.synced ? Colors.transparent : accent,
                    shape: BoxShape.circle),
              ),
              SizedBox(
                width: 46,
                child: Text(
                    DateFormat('HH:mm').format(m.createdAt.toLocal()),
                    style: TextStyle(color: faint, fontSize: 12.5)),
              ),
              Expanded(
                child: Text(m.text,
                    style: TextStyle(fontSize: 16, color: ink, height: 1.4)),
              ),
            ]),
          ));
        }
        return ListView(padding: const EdgeInsets.only(bottom: 40), children: widgets);
      },
    );
  }
}
