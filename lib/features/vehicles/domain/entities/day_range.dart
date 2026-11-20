import 'package:equatable/equatable.dart';

/// Whole days from [start] to [end], both included. Times are dropped.
class DayRange extends Equatable {
  DayRange(DateTime start, DateTime end)
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day);

  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}
