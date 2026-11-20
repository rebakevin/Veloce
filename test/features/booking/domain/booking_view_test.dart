import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/domain/enums/user_role.dart';

import '../support/booking_test_data.dart';

void main() {
  test('open, active and past follow the effective status', () {
    expect(bookingView(status: BookingStatus.pending).isOpen, isTrue);
    expect(bookingView(status: BookingStatus.approved).isOpen, isTrue);
    expect(bookingView(status: BookingStatus.confirmed).isActive, isTrue);
    expect(bookingView(status: BookingStatus.review).isActive, isTrue);
    expect(bookingView(status: BookingStatus.cancelled).isPast, isTrue);
    expect(bookingView(status: BookingStatus.completed).isPast, isTrue);
  });

  test('contact unlocks only after payment', () {
    expect(
      bookingView(status: BookingStatus.approved).isContactUnlocked,
      isFalse,
    );
    expect(
      bookingView(status: BookingStatus.confirmed).isContactUnlocked,
      isTrue,
    );
    expect(bookingView(status: BookingStatus.active).isContactUnlocked, isTrue);
  });

  test('the counterpart is the other party', () {
    final view = bookingView();
    expect(view.counterpartFor(UserRole.renter).id, view.owner.id);
    expect(view.counterpartFor(UserRole.owner).id, view.renter.id);
  });
}
