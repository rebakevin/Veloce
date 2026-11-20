import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';

class RepairExpensePage extends StatefulWidget {
  const RepairExpensePage({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<RepairExpensePage> createState() => _RepairExpensePageState();
}

class _RepairExpensePageState extends State<RepairExpensePage> {
  final _firestore = GetIt.I<FirebaseFirestore>();
  final _session = GetIt.I<AuthSession>();
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  XFile? _receipt;
  String? _editingId;
  String? _editingReceiptUrl;
  bool _loading = false;
  String? _errorMessage;

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection('repairExpenses');

  Stream<QuerySnapshot<Map<String, dynamic>>> get _expenseStream =>
      _expenses.where('bookingId', isEqualTo: widget.bookingId).snapshots();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      setState(() {
        _receipt = image;
        _errorMessage = null;
      });
    }
  }

  Future<String?> _uploadReceipt(String expenseId) async {
    if (_receipt == null) return _editingReceiptUrl;

    final bytes = await _receipt!.readAsBytes();
    final reference = _storage.ref().child(
      'repair-expenses/${widget.bookingId}/$expenseId.jpg',
    );

    await reference.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

    return reference.getDownloadURL();
  }

  Future<void> _saveExpense() async {
    final userId = _session.currentUserId;
    final amount = int.tryParse(_amountController.text.trim());
    final description = _descriptionController.text.trim();

    if (userId == null) return;

    if (amount == null || amount <= 0 || description.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a valid amount and description.';
      });
      return;
    }

    if (_receipt == null && _editingReceiptUrl == null) {
      setState(() {
        _errorMessage = 'Please attach a receipt photo.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final expenseId = _editingId ?? _expenses.doc().id;
      final receiptUrl = await _uploadReceipt(expenseId);

      final data = <String, dynamic>{
        'bookingId': widget.bookingId,
        'ownerId': userId,
        'amount': amount,
        'description': description,
        'receiptUrl': receiptUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _expenses.doc(expenseId).set(data);
      } else {
        await _expenses.doc(expenseId).update(data);
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _editingId = null;
        _editingReceiptUrl = null;
        _receipt = null;
        _amountController.clear();
        _descriptionController.clear();
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Repair expense saved.')));
    } on Object catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Could not save expense: $error';
      });
    }
  }

  void _editExpense(String id, Map<String, dynamic> data) {
    setState(() {
      _editingId = id;
      _amountController.text = data['amount']?.toString() ?? '';
      _descriptionController.text = data['description']?.toString() ?? '';
      _editingReceiptUrl = data['receiptUrl']?.toString();
      _receipt = null;
      _errorMessage = null;
    });
  }

  Future<void> _deleteExpense(String id, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'This will permanently delete this repair expense.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _expenses.doc(id).delete();

      final receiptUrl = data['receiptUrl']?.toString();
      if (receiptUrl != null && receiptUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(receiptUrl).delete();
        } on Object {
          // The expense is deleted even if its receipt is unavailable.
        }
      }

      if (!mounted) return;

      if (_editingId == id) {
        _clearForm();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Repair expense deleted.')));
    } on Object catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete expense: $error')),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _editingReceiptUrl = null;
      _receipt = null;
      _amountController.clear();
      _descriptionController.clear();
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _session.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Repair expenses')),
      body: StreamBuilder<Result<Booking>>(
        stream: GetIt.I<BookingLookup>().watch(widget.bookingId),
        builder: (context, bookingSnapshot) {
          if (bookingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!bookingSnapshot.hasData) {
            return const Center(child: Text('Unable to load booking.'));
          }

          return bookingSnapshot.data!.when(
            success: (booking) {
              if (booking.ownerId != userId) {
                return const Center(
                  child: Text('Only the vehicle owner can manage expenses.'),
                );
              }

              return _buildExpenseContent();
            },
            failure: (failure) {
              return Center(child: Text(failure.message));
            },
          );
        },
      ),
    );
  }

  Widget _buildExpenseContent() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _expenseStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load repair expenses.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data?.docs ?? [];
        final total = expenses.fold<int>(
          0,
          (totalAmount, item) =>
              totalAmount + ((item.data()['amount'] as num?)?.toInt() ?? 0),
        );

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Manage repair expenses',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Total repair expenses: $total RWF'),
            const SizedBox(height: 24),
            Text(
              _editingId == null ? 'Add repair expense' : 'Edit repair expense',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickReceipt,
              icon: const Icon(Icons.photo_camera),
              label: Text(
                _receipt != null
                    ? 'Receipt selected'
                    : _editingReceiptUrl != null
                    ? 'Replace receipt photo'
                    : 'Add receipt photo',
              ),
            ),
            if (_receipt != null) ...[
              const SizedBox(height: 8),
              Text(_receipt!.name),
            ] else if (_editingReceiptUrl != null) ...[
              const SizedBox(height: 8),
              const Text('Existing receipt photo is attached.'),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveExpense,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(
                        _editingId == null ? 'Save expense' : 'Update expense',
                      ),
              ),
            ),
            if (_editingId != null)
              TextButton(
                onPressed: _loading ? null : _clearForm,
                child: const Text('Cancel editing'),
              ),
            const Divider(height: 36),
            const Text(
              'Saved expenses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              const Text('No repair expenses have been added.')
            else
              ...expenses.map((document) {
                final data = document.data();
                final amount = (data['amount'] as num?)?.toInt() ?? 0;
                final description = data['description']?.toString() ?? '';
                final receiptUrl = data['receiptUrl']?.toString();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$amount RWF',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(description),
                        if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              receiptUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text('Receipt image unavailable.');
                              },
                            ),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Edit expense',
                              onPressed: () {
                                _editExpense(document.id, data);
                              },
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: 'Delete expense',
                              onPressed: () {
                                _deleteExpense(document.id, data);
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
