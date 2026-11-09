import 'package:equatable/equatable.dart';

/// An owner's MTN MoMo payout number (private).
class PayoutMethod extends Equatable {
  const PayoutMethod({required this.userId, required this.momoNumber});

  final String userId;
  final String momoNumber;

  PayoutMethod copyWith({String? userId, String? momoNumber}) {
    return PayoutMethod(
      userId: userId ?? this.userId,
      momoNumber: momoNumber ?? this.momoNumber,
    );
  }

  @override
  List<Object?> get props => [userId, momoNumber];
}
