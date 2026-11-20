import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:veloce/core/domain/enums/transmission.dart';
import 'package:veloce/core/domain/enums/vehicle_type.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../../domain/entities/search_options.dart';
import '../../domain/entities/vehicle_filters.dart';
import '../bloc/filters_cubit.dart';

/// Filters route. Pops with the chosen [VehicleFilters].
class FiltersPage extends StatelessWidget {
  const FiltersPage({super.key, this.initial = VehicleFilters.none});

  final VehicleFilters initial;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FiltersCubit>(
      create: (_) => FiltersCubit(initial),
      child: const _FiltersBody(),
    );
  }
}

class _FiltersBody extends StatelessWidget {
  const _FiltersBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FiltersCubit, VehicleFilters>(
      builder: (context, filters) => Scaffold(
        appBar: PageAppBar(title: 'Filters (${filters.activeCount})'),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          children: [
            const _PriceFields(),
            const SizedBox(height: AppSpacing.xl),
            _ChoiceSection<VehicleType>(
              title: 'Vehicle type',
              values: VehicleType.values,
              label: (value) => value.label,
              selected: filters.type,
              onSelected: (value) =>
                  context.read<FiltersCubit>().typeChanged(value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ChoiceSection<Transmission>(
              title: 'Transmission',
              values: Transmission.values,
              label: (value) => value.label,
              selected: filters.transmission,
              onSelected: (value) =>
                  context.read<FiltersCubit>().transmissionChanged(value),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ChoiceSection<int>(
              title: 'Seats',
              values: SearchOptions.seatOptions,
              label: (value) => '$value+',
              selected: filters.minSeats,
              onSelected: (value) =>
                  context.read<FiltersCubit>().seatsChanged(value),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<FiltersCubit>().reset(),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Apply',
                    onPressed: () =>
                        context.pop(context.read<FiltersCubit>().state),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceFields extends StatefulWidget {
  const _PriceFields();

  @override
  State<_PriceFields> createState() => _PriceFieldsState();
}

class _PriceFieldsState extends State<_PriceFields> {
  late final TextEditingController _min;
  late final TextEditingController _max;

  @override
  void initState() {
    super.initState();
    final filters = context.read<FiltersCubit>().state;
    _min = TextEditingController(text: filters.minPrice?.toString() ?? '');
    _max = TextEditingController(text: filters.maxPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FiltersCubit, VehicleFilters>(
      listenWhen: (previous, current) =>
          previous.minPrice != current.minPrice ||
          previous.maxPrice != current.maxPrice,
      listener: (context, filters) {
        if (filters.minPrice == null && _min.text.isNotEmpty) _min.clear();
        if (filters.maxPrice == null && _max.text.isNotEmpty) _max.clear();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Price per day (RWF)', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'Min'),
                  onChanged: (value) => context
                      .read<FiltersCubit>()
                      .minPriceChanged(int.tryParse(value)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(hintText: 'Max'),
                  onChanged: (value) => context
                      .read<FiltersCubit>()
                      .maxPriceChanged(int.tryParse(value)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.values,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final String Function(T value) label;
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: const Text('Any'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
            for (final value in values)
              ChoiceChip(
                label: Text(label(value)),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}
