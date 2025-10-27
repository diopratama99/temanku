import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';

class ImportExportPage extends StatefulWidget {
  const ImportExportPage({super.key});

  @override
  State<ImportExportPage> createState() => _ImportExportPageState();
}

class _ImportExportPageState extends State<ImportExportPage> {
  late DateTime _start;
  late DateTime _end;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
  }

  String _iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _exportCsv() async {
    setState(() => _busy = true);
    final db = context.read<AppDatabase>();
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final rows = await db.db.rawQuery(
      '''
      SELECT t.date, t.type, c.name as category, t.amount, t.source_or_payee, t.account, t.notes
      FROM transactions t JOIN categories c ON c.id=t.category_id
      WHERE t.user_id=? AND t.date BETWEEN ? AND ?
      ORDER BY t.date ASC
    ''',
      [userId, _iso(_start), _iso(_end)],
    );
    final csvRows = <List<dynamic>>[
      [
        'date',
        'type',
        'category',
        'amount',
        'source_or_payee',
        'account',
        'notes',
      ],
      ...rows.map(
        (r) => [
          r['date'],
          r['type'],
          r['category'],
          r['amount'],
          r['source_or_payee'] ?? '',
          r['account'] ?? '',
          r['notes'] ?? '',
        ],
      ),
    ];
    final csv = const ListToCsvConverter().convert(csvRows);
    final tempDir = await getTemporaryDirectory();
    final file = File(
      p.join(tempDir.path, 'temanku_${_iso(_start)}_${_iso(_end)}.csv'),
    );
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Export Temanku');
    setState(() => _busy = false);
  }

  Future<void> _importCsv() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (res == null || res.files.single.path == null) return;
    setState(() => _busy = true);
    final file = File(res.files.single.path!);
    final content = await file.readAsString();
    final parsed = const CsvToListConverter().convert(content, eol: '\n');
    // Expect header in first row
    final header = parsed.first.map((e) => e.toString()).toList();
    final idx = {
      for (var i = 0; i < header.length; i++) header[i].toLowerCase(): i,
    };
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final db = context.read<AppDatabase>().db;
    for (int i = 1; i < parsed.length; i++) {
      final row = parsed[i];
      String date = row[idx['date']!].toString();
      String type = row[idx['type']!].toString();
      String categoryName = row[idx['category']!].toString();
      final amount = double.tryParse(row[idx['amount']!].toString()) ?? 0.0;
      final payee = idx.containsKey('source_or_payee')
          ? row[idx['source_or_payee']!].toString()
          : '';
      final account = idx.containsKey('account')
          ? row[idx['account']!].toString()
          : '';
      final notes = idx.containsKey('notes')
          ? row[idx['notes']!].toString()
          : '';

      // Ensure category exists
      final catRows = await db.query(
        'categories',
        where: 'user_id=? AND type=? AND name=?',
        whereArgs: [userId, type, categoryName],
        limit: 1,
      );
      int catId;
      if (catRows.isEmpty) {
        catId = await db.insert('categories', {
          'user_id': userId,
          'type': type,
          'name': categoryName,
        });
      } else {
        catId = catRows.first['id'] as int;
      }

      await db.insert('transactions', {
        'user_id': userId,
        'date': date,
        'type': type,
        'category_id': catId,
        'amount': amount,
        'source_or_payee': payee,
        'account': account,
        'notes': notes,
      });
    }
    setState(() => _busy = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Import selesai')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import / Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Rentang tanggal untuk Export'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _start,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _start = picked);
                  },
                  child: Text('Start: ${_iso(_start)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _end,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _end = picked);
                  },
                  child: Text('End: ${_iso(_end)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _exportCsv,
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _importCsv,
            icon: const Icon(Icons.upload),
            label: const Text('Import CSV'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
