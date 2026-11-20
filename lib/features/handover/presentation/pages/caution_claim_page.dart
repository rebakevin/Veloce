import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/constants/firestore_paths.dart';
import 'package:veloce/core/data/services/booking_lookup.dart';
import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/claim_response.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/handover/domain/repositories/handover_repository.dart';

class CautionClaimPage extends StatefulWidget {
  const CautionClaimPage({required this.bookingId, super.key});

  final String bookingId;

  @override
  State<CautionClaimPage> createState() => _CautionClaimPageState();
}

class _CautionClaimPageState extends State<CautionClaimPage> {
  final _repository = GetIt.I<HandoverRepository>();
  final _session = GetIt.I<AuthSession>();
  final _firestore = GetIt.I<FirebaseFirestore>();

  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _evidenceController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  DocumentReference<Map<String, dynamic>> get _claimDocument =>
      _firestore.collection(FirestorePaths.cautionClaims).doc(widget.bookingId);

  List<String> get _evidenceUrls => _evidenceController.text
      .split(',')
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList();

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Future<void> _submitClaim() async {
    final userId = _session.currentUserId;
    final amount = int.tryParse(_amountController.text.trim());
    final reason = _reasonController.text.trim();

    if (userId == null) return;

    if (amount == null || amount <= 0 || reason.isEmpty) {
      setState(() => _errorMessage = 'Enter a valid amount and reason.');
      return;
    }

    await _runAction(
      () => _repository.submitClaim(
        bookingId: widget.bookingId,
        userId: userId,
        amount: amount,
        reason: reason,
        evidenceUrls: _evidenceUrls,
      ),
    );
  }

  Future<void> _respondToClaim(ClaimResponse response) async {
    final userId = _session.currentUserId;
    if (userId == null) return;

    await _runAction(
      () => _repository.respondToClaim(
        bookingId: widget.bookingId,
        userId: userId,
        response: response,
      ),
    );
  }

  Future<void> _reviseClaim() async {
    final userId = _session.currentUserId;
    final amount = int.tryParse(_amountController.text.trim());
    final reason = _reasonController.text.trim();

    if (userId == null) return;

    if (amount == null || amount <= 0 || reason.isEmpty) {
      setState(() => _errorMessage = 'Enter a valid amount and reason.');
      return;
    }

    await _runAction(
      () => _repository.reviseClaim(
        bookingId: widget.bookingId,
        userId: userId,
        amount: amount,
        reason: reason,
        evidenceUrls: _evidenceUrls,
      ),
    );
  }

  Future<void> _refundCaution() async {
    final userId = _session.currentUserId;
    if (userId == null) return;

    await _runAction(
      () => _repository.refundCaution(
        bookingId: widget.bookingId,
        userId: userId,
      ),
    );
  }

  Future<void> _runAction(Future<Result<Booking>> Function() action) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await action();

    if (!mounted) return;

    result.when(
      success: (_) {
        setState(() => _loading = false);
      },
      failure: (failure) {
        setState(() {
          _loading = false;
          _errorMessage = failure.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _session.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Caution claim')),
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
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _claimDocument.snapshots(),
                builder: (context, claimSnapshot) {
                  if (claimSnapshot.hasError) {
                    return const Center(
                      child: Text('Unable to load claim details.'),
                    );
                  }

                  if (claimSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final claim = claimSnapshot.data?.data();

                  return _buildContent(booking, claim, userId);
                },
              );
            },
            failure: (failure) {
              return Center(child: Text(failure.message));
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(
    Booking booking,
    Map<String, dynamic>? claim,
    String? userId,
  ) {
    final isOwner = booking.ownerId == userId;
    final isRenter = booking.renterId == userId;

    final bothReturned =
        booking.ownerReturnConfirmedAt != null &&
        booking.renterReturnConfirmedAt != null;

    final claimExists = claim != null;
    final response = claim?['renterResponse']?.toString() ?? 'none';
    final claimStatus = claim?['status']?.toString() ?? 'open';

    final amount = claim?['currentAmount'] ?? 0;
    final reason = claim?['reason']?.toString() ?? '';
    final evidence =
        (claim?['evidenceUrls'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle damage or issue claim',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (claimExists) ...[
            _detailRow('Claim amount', '$amount RWF'),
            _detailRow('Reason', reason),
            _detailRow('Claim status', claimStatus),
            _detailRow('Renter response', response),
            if (evidence.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Evidence references',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...evidence.map(
                (url) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SelectableText(url),
                ),
              ),
            ],
            const Divider(height: 32),
          ],

          if (isOwner &&
              booking.status == BookingStatus.returning &&
              bothReturned &&
              !claimExists) ...[
            _claimForm(
              title: 'Submit a caution claim',
              buttonLabel: 'Submit claim',
              onPressed: _submitClaim,
            ),
          ] else if (isRenter &&
              booking.status == BookingStatus.review &&
              claimExists &&
              claimStatus == 'open' &&
              response == 'none') ...[
            const Text(
              'Review the owner claim and choose whether you agree or dispute it.',
            ),
            const SizedBox(height: 16),
            _actionButton(
              label: 'Agree to claim',
              onPressed: () => _respondToClaim(ClaimResponse.agreed),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _loading
                  ? null
                  : () => _respondToClaim(ClaimResponse.disputed),
              child: const Text('Dispute claim'),
            ),
          ] else if (isOwner &&
              booking.status == BookingStatus.review &&
              claimExists &&
              response == 'disputed' &&
              claimStatus == 'open') ...[
            const Text(
              'The renter disputed the claim. You can revise the claim to the same or a lower amount, or refund the caution.',
            ),
            const SizedBox(height: 16),
            _claimForm(
              title: 'Revise claim',
              buttonLabel: 'Submit revised claim',
              onPressed: _reviseClaim,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading ? null : _refundCaution,
              child: const Text('Refund caution'),
            ),
          ] else if (claimExists && claimStatus == 'settled') ...[
            const Text('The claim has been settled.'),
          ] else if (claimExists && claimStatus == 'refunded') ...[
            const Text('The caution has been refunded.'),
          ] else if (booking.status == BookingStatus.completed) ...[
            const Text('This booking has been completed.'),
          ] else if (claimExists && response == 'disputed') ...[
            const Text(
              'The claim is disputed and awaiting the owner’s next action.',
            ),
          ] else if (claimExists) ...[
            const Text('The claim is awaiting a response or settlement.'),
          ] else ...[
            const Text('The booking is not ready for a caution claim.'),
          ],

          if (_loading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _claimForm({
    required String title,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Claim amount (RWF)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for claim',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _evidenceController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Evidence photo URLs (comma separated)',
            hintText: 'Paste uploaded photo URLs',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _actionButton(label: buttonLabel, onPressed: onPressed),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        child: Text(label),
      ),
    );
  }
}
