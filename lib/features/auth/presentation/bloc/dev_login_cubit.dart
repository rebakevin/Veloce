import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/data/services/verification_sim.dart';

import '../../data/dev_sign_in.dart';
import '../../domain/dev_account.dart';

enum DevLoginStatus { idle, signingIn, signedIn, failed }

class DevLoginState extends Equatable {
  const DevLoginState({
    this.status = DevLoginStatus.idle,
    this.message,
    this.momoSucceeds = true,
    this.verificationSucceeds = true,
  });

  final DevLoginStatus status;
  final String? message;
  final bool momoSucceeds;
  final bool verificationSucceeds;

  DevLoginState copyWith({
    DevLoginStatus? status,
    String? message,
    bool? momoSucceeds,
    bool? verificationSucceeds,
  }) => DevLoginState(
    status: status ?? this.status,
    message: message,
    momoSucceeds: momoSucceeds ?? this.momoSucceeds,
    verificationSucceeds: verificationSucceeds ?? this.verificationSucceeds,
  );

  @override
  List<Object?> get props => [
    status,
    message,
    momoSucceeds,
    verificationSucceeds,
  ];
}

/// Debug-only quick login plus the simulation switches (payment, verification).
class DevLoginCubit extends Cubit<DevLoginState> {
  DevLoginCubit({
    required this._signIn,
    required MomoGatewaySim momo,
    required VerificationSim verification,
  }) : _momo = momo,
       _verification = verification,
       super(
         DevLoginState(
           momoSucceeds: momo.shouldSucceed,
           verificationSucceeds: verification.shouldSucceed,
         ),
       );

  final DevSignIn _signIn;
  final MomoGatewaySim _momo;
  final VerificationSim _verification;

  Future<void> signInAs(DevAccount account) async {
    if (state.status == DevLoginStatus.signingIn) return;
    emit(state.copyWith(status: DevLoginStatus.signingIn));
    final result = await _signIn.signIn(account);
    if (isClosed) return;
    emit(
      result.when(
        success: (_) => state.copyWith(status: DevLoginStatus.signedIn),
        failure: (failure) => state.copyWith(
          status: DevLoginStatus.failed,
          message: failure.message,
        ),
      ),
    );
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    if (isClosed) return;
    emit(state.copyWith(status: DevLoginStatus.idle));
  }

  void setMomoSucceeds({required bool value}) {
    _momo.shouldSucceed = value;
    emit(state.copyWith(momoSucceeds: value));
  }

  void setVerificationSucceeds({required bool value}) {
    _verification.shouldSucceed = value;
    emit(state.copyWith(verificationSucceeds: value));
  }
}
