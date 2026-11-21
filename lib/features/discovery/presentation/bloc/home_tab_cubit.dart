import 'package:flutter_bloc/flutter_bloc.dart';

/// Which tab of the renter home is shown: 0 Explore, 1 Saved.
class HomeTabCubit extends Cubit<int> {
  HomeTabCubit() : super(0);

  void select(int tab) => emit(tab);
}
