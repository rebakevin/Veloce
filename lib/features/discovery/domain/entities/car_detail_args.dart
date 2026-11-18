import 'package:equatable/equatable.dart';

/// Dates carried from search/results into the car detail page.
class CarDetailArgs extends Equatable {
  const CarDetailArgs({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}
