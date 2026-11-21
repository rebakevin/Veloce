import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:veloce/core/data/services/momo_gateway_sim.dart';
import 'package:veloce/core/data/services/verification_sim.dart';

import '../../data/dev_sign_in.dart';
import '../../domain/dev_account.dart';

enum DevToolsStatus { idle, signingIn, signedIn, failed }

class DevToolsState extends Equatable {
  const DevToolsState({
    this.status = DevToolsStatus.idle,
    this.message,
    this.momoSucceeds = true,
    this.verificationSucceeds = true,
  });

  final DevToolsStatus status;
  final String? message;
  final bool momoSucceeds;
  final bool verificationSucceeds;

  DevToolsState copyWith({
    DevToolsStatus? status,
    String? message,
    bool? momoSucceeds,
    bool? verificationSucceeds,
  }) => DevToolsState(
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

/// Debug-only dev tools: sign in as a seeded account and flip the simulation
/// switches (payment, verification).
class DevToolsCubit extends Cubit<DevToolsState> {
  DevToolsCubit({
    required this._signIn,
    required MomoGatewaySim momo,
    required VerificationSim verification,
  }) : _momo = momo,
       _verification = verification,
       super(
         DevToolsState(
           momoSucceeds: momo.shouldSucceed,
           verificationSucceeds: verification.shouldSucceed,
         ),
       );

  final DevSignIn _signIn;
  final MomoGatewaySim _momo;
  final VerificationSim _verification;

  Future<void> signInAs(DevAccount account) async {
    if (state.status == DevToolsStatus.signingIn) return;
    emit(state.copyWith(status: DevToolsStatus.signingIn));
    final result = await _signIn.signIn(account);
    if (isClosed) return;
    emit(
      result.when(
        success: (_) => state.copyWith(status: DevToolsStatus.signedIn),
        failure: (failure) => state.copyWith(
          status: DevToolsStatus.failed,
          message: failure.message,
        ),
      ),
    );
  }

  Future<void> signOut() async {
    await _signIn.signOut();
    if (isClosed) return;
    emit(state.copyWith(status: DevToolsStatus.idle));
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
