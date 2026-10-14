class ArtifactModel {
  final String id;
  final String name;
  final String category; // 'Senjata', 'Kendaraan', 'Semua'
  final String era;
  final String origin;
  final String operation;
  final String mainWeapon;
  final String caliber;
  final String commander;
  final String description;
  final String imageUrl;
  final String historicalContext;

  const ArtifactModel({
    required this.id,
    required this.name,
    required this.category,
    this.era = '',
    this.origin = '',
    this.operation = '',
    this.mainWeapon = '',
    this.caliber = '',
    this.commander = '',
    required this.description,
    required this.imageUrl,
    this.historicalContext = '',
  });
}

class TicketType {
  final String name;
  final int price;
  final String description;
  int quantity;

  TicketType({
    required this.name,
    required this.price,
    required this.description,
    this.quantity = 0,
  });
}

class BookingModel {
  final String bookingId;
  final String visitorName;
  final String email;
  final String phone;
  final DateTime visitDate;
  final String visitTime;
  final List<TicketType> tickets;
  final String paymentMethod;
  final int total;

  const BookingModel({
    required this.bookingId,
    required this.visitorName,
    required this.email,
    required this.phone,
    required this.visitDate,
    required this.visitTime,
    required this.tickets,
    required this.paymentMethod,
    required this.total,
  });
}
