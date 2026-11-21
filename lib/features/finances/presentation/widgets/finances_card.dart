import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';

import '../../domain/enums/finance_period.dart';
import '../../domain/repositories/finances_repository.dart';

sealed class FinancesCardState extends Equatable {
  const FinancesCardState();

  @override
  List<Object?> get props => [];
}

final class FinancesCardLoading extends FinancesCardState {
  const FinancesCardLoading();
}

final class FinancesCardLoaded extends FinancesCardState {
  const FinancesCardLoaded({required this.earned, required this.losses});

  final int earned;
  final int losses;

  @override
  List<Object?> get props => [earned, losses];
}

final class FinancesCardFailure extends FinancesCardState {
  const FinancesCardFailure();
}

class FinancesCardCubit extends Cubit<FinancesCardState> {
  FinancesCardCubit({required this._repository, required this._session})
    : super(const FinancesCardLoading());

  final FinancesRepository _repository;
  final AuthSession _session;

  Future<void> load() async {
    final ownerId = _session.currentUserId;
    if (ownerId == null) {
      emit(const FinancesCardFailure());
      return;
    }

    final result = await _repository.getOwnerFinances(
      ownerId: ownerId,
      period: FinancePeriod.thisMonth,
    );

    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          FinancesCardLoaded(
            earned: value.totalEarned,
            losses: value.totalLosses,
          ),
        );
      case Failure():
        emit(const FinancesCardFailure());
    }
  }
}

/// Slot owned by Phase 6; shown on OwnerHomePage.
class FinancesCard extends StatelessWidget {
  const FinancesCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!GetIt.instance.isRegistered<FinancesRepository>() ||
        !GetIt.instance.isRegistered<AuthSession>()) {
      return const SizedBox.shrink();
    }
    return BlocProvider(
      create: (_) => FinancesCardCubit(
        repository: GetIt.instance<FinancesRepository>(),
        session: GetIt.instance<AuthSession>(),
      )..load(),
      child: const _FinancesCardView(),
    );
  }
}

class _FinancesCardView extends StatelessWidget {
  const _FinancesCardView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: () => context.push(RouteNames.ownerFinances),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Finances this month',
                    style: AppTextStyles.cardTitle.copyWith(color: colors.ink),
                  ),
                  Icon(Icons.chevron_right, color: colors.muted, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              BlocBuilder<FinancesCardCubit, FinancesCardState>(
                builder: (context, state) => switch (state) {
                  FinancesCardLoading() => const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  FinancesCardFailure() => Text(
                    'Could not load finances summary.',
                    style: AppTextStyles.caption.copyWith(color: colors.muted),
                  ),
                  FinancesCardLoaded(:final earned, :final losses) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earned',
                              style: AppTextStyles.caption.copyWith(
                                color: colors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.rwf(earned),
                              style: AppTextStyles.cardTitle.copyWith(
                                color: colors.brand,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Losses',
                              style: AppTextStyles.caption.copyWith(
                                color: colors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.rwf(losses),
                              style: AppTextStyles.cardTitle.copyWith(
                                color: losses > 0 ? colors.danger : colors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
