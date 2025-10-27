import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../state/auth_notifier.dart';
import 'transactions_page_modern.dart';

class AddTransactionSimplePage extends StatefulWidget {
  final bool showHistoryButton;

  const AddTransactionSimplePage({super.key, this.showHistoryButton = true});

  @override
  State<AddTransactionSimplePage> createState() =>
      _AddTransactionSimplePageState();
}

class _AddTransactionSimplePageState extends State<AddTransactionSimplePage> {
  DateTime _date = DateTime.now();
  String _type = 'expense';
  int? _categoryId;
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _notes = TextEditingController();
  String _account = 'Transfer';
  List<Map<String, dynamic>> _cats = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && (args == 'income' || args == 'expense')) {
        setState(() {
          _type = args;
        });
      }
      _loadCats();
    });
  }

  Future<void> _loadCats() async {
    try {
      final userId = context.read<AuthNotifier>().user!['id'] as int;
      final rows = await context.read<AppDatabase>().db.query(
        'categories',
        where: 'user_id=? AND type=?',
        whereArgs: [userId, _type],
        orderBy: 'name',
      );
      if (!mounted) return;
      setState(() {
        _cats = rows;
        if (_cats.isEmpty) {
          _categoryId = null;
        } else {
          final has = _cats.any((e) => e['id'] == _categoryId);
          if (!has) _categoryId = _cats.first['id'] as int;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cats = [];
      });
    }
  }

  Future<void> _save() async {
    final userId = context.read<AuthNotifier>().user!['id'] as int;
    final amount = num.tryParse(
      _amount.text.replaceAll('.', '').replaceAll(',', '.'),
    )?.toDouble();
    if (amount == null || _categoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi data')));
      return;
    }
    await context.read<AppDatabase>().db.insert('transactions', {
      'user_id': userId,
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'type': _type,
      'category_id': _categoryId,
      'amount': amount,
      'source_or_payee': _payee.text,
      'account': _account,
      'notes': _notes.text,
    });
    if (!mounted) return;

    // Show success dialog with animation
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) => ScaleTransition(
        scale: CurvedAnimation(
          parent: AnimationController(
            duration: const Duration(milliseconds: 300),
            vsync: Navigator.of(dialogContext),
          )..forward(),
          curve: Curves.easeOutBack,
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated success icon with glow effect
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                // Confetti-like decoration
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text(
                      'Berhasil!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF157347),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('🎉', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Transaksi berhasil ditambahkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Gradient button
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Center(
                        child: Text(
                          'Oke, Mantap! 👍',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Reset form
    if (!mounted) return;
    setState(() {
      _amount.clear();
      _payee.clear();
      _notes.clear();
      _date = DateTime.now();
    });

    // Wait a bit then close the add transaction page
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF157347),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Transaksi Baru',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: widget.showHistoryButton
            ? [
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const TransactionsPageModern(hideAddButton: true),
                      ),
                    );
                  },
                  tooltip: 'Riwayat Transaksi',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Type Selector - Compact
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _type = 'expense';
                          _categoryId = null;
                        });
                        _loadCats();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'expense'
                              ? const Color(0xFFEF4444)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _type == 'expense'
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_down_rounded,
                              color: _type == 'expense'
                                  ? Colors.white
                                  : Colors.black54,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: TextStyle(
                                color: _type == 'expense'
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _type = 'income';
                          _categoryId = null;
                        });
                        _loadCats();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'income'
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _type == 'income'
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              color: _type == 'income'
                                  ? Colors.white
                                  : Colors.black54,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: TextStyle(
                                color: _type == 'income'
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount Input - Compact
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _type == 'expense'
                                ? const Color(0xFFEF4444).withOpacity(0.05)
                                : const Color(0xFF10B981).withOpacity(0.05),
                            _type == 'expense'
                                ? const Color(0xFFFCA5A5).withOpacity(0.05)
                                : const Color(0xFF6EE7B7).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _type == 'expense'
                              ? const Color(0xFFEF4444).withOpacity(0.2)
                              : const Color(0xFF10B981).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jumlah ${_type == 'expense' ? 'Pengeluaran' : 'Pemasukan'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _type == 'expense'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Rp ',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: _type == 'expense'
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _amount,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  autofocus: true,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: _type == 'expense'
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF10B981),
                                    height: 1.2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Category Selection - Compact (Full Width)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value:
                                          _cats.any(
                                            (e) => e['id'] == _categoryId,
                                          )
                                          ? _categoryId
                                          : null,
                                      isExpanded: true,
                                      hint: const Text(
                                        'Pilih kategori',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      items: [
                                        for (final c in _cats)
                                          DropdownMenuItem(
                                            value: c['id'] as int,
                                            child: Row(
                                              children: [
                                                Text(
                                                  c['emoji'] as String? ?? '📁',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  c['name'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _categoryId = v),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Date & Payment Method Row - Side by Side
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date Selection - Compact
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null)
                                  setState(() => _date = picked);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.blue.shade700,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd/MM/yy').format(_date),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Payment Method Dropdown - Compact
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _account == 'Transfer'
                                          ? Icons.account_balance_rounded
                                          : _account == 'Tunai'
                                          ? Icons.payments_rounded
                                          : Icons.phone_android_rounded,
                                      color: Colors.purple.shade700,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _account,
                                        isExpanded: true,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Transfer',
                                            child: Text('Bank'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Tunai',
                                            child: Text('Tunai'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'E-Wallet',
                                            child: Text('E-Wallet'),
                                          ),
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _account = v!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Keterangan - Compact
                    TextField(
                      controller: _payee,
                      maxLines: 2,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        labelText: 'Keterangan',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        hintText: 'Contoh: Gaji bulan ini, Belanja bulanan',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.description_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF157347),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 12),

                    // Catatan - Compact
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        hintText: 'Tambahkan catatan...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            Icons.note_alt_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF157347),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Fixed Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.transparent),
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _type == 'expense'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _type == 'expense'
                              ? 'Simpan Pengeluaran'
                              : 'Simpan Pemasukan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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
}
