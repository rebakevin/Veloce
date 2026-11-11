import 'package:flutter_bloc/flutter_bloc.dart';

/// The visible onboarding slide, for the dots and the last-slide buttons.
class PageIndexCubit extends Cubit<int> {
  PageIndexCubit() : super(0);

  void select(int index) => emit(index);
}
