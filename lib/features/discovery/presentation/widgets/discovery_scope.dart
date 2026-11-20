import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../bloc/favourites_bloc.dart';
import '../bloc/search_cubit.dart';

/// Provides the feature-wide search form and the shared favourites state.
class DiscoveryScope extends StatelessWidget {
  const DiscoveryScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SearchCubit>.value(value: GetIt.instance<SearchCubit>()),
        BlocProvider<FavouritesBloc>.value(
          value: GetIt.instance<FavouritesBloc>(),
        ),
      ],
      child: child,
    );
  }
}
