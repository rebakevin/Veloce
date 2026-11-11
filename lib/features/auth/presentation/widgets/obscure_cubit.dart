import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether a password field hides its text. Purely visual state of one field.
class ObscureCubit extends Cubit<bool> {
  ObscureCubit() : super(true);

  void toggle() => emit(!state);
}
