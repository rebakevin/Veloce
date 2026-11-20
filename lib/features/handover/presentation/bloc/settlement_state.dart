import 'package:equatable/equatable.dart';

enum SettlementStatus { idle, loading, failure }

class SettlementState extends Equatable {
  const SettlementState({this.status = SettlementStatus.idle, this.message});

  final SettlementStatus status;

  /// Set only when [status] is [SettlementStatus.failure].
  final String? message;

  bool get isLoading => status == SettlementStatus.loading;

  @override
  List<Object?> get props => [status, message];
}
