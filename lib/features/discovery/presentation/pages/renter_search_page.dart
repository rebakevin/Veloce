import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/navigation/route_names.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/search_cubit.dart';
import '../bloc/search_state.dart';
import '../widgets/discovery_scope.dart';
import '../widgets/renter_search_form.dart';
import '../widgets/type_chip_row.dart';

/// Area + date picker opened from the home search card.
class RenterSearchPage extends StatelessWidget {
  const RenterSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiscoveryScope(child: _SearchBody());
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) => Scaffold(
        appBar: const PageAppBar(title: 'Search cars'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            const Text('Where and when?', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.md),
            RenterSearchForm(
              state: state,
              onAreaChanged: (area) =>
                  context.read<SearchCubit>().areaChanged(area),
              onDatesChanged: (start, end) =>
                  context.read<SearchCubit>().datesChanged(start, end),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Type', style: AppTextStyles.caption),
            const SizedBox(height: AppSpacing.sm),
            HomeTypeChips(
              selected: state.typeChip,
              onSelected: (type) =>
                  context.read<SearchCubit>().typeChipChanged(type),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Show cars',
              onPressed: state.query == null
                  ? null
                  : () => unawaited(_search(context)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _search(BuildContext context) async {
    final search = context.read<SearchCubit>();
    final query = search.state.query;
    if (query == null) return;
    await search.savePreferences();
    if (!context.mounted) return;
    unawaited(context.push(RouteNames.renterResults, extra: query));
  }
}
