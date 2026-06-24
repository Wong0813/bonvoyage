class ItineraryItemModel {
  final int id;
  final int bookingId;
  final int dayNumber;
  final String timeSlot;
  final String activity;
  final String location;
  final String? notes;

  const ItineraryItemModel({
    required this.id,
    required this.bookingId,
    required this.dayNumber,
    required this.timeSlot,
    required this.activity,
    required this.location,
    this.notes,
  });
}
