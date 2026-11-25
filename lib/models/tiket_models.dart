int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String _parseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
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

/// Model kategori tiket dari backend
class TiketCategory {
  final int id;
  final String badge;
  final String badgeBg;
  final String badgeColor;
  final String title;
  final int price;
  final int kuota;
  final String status;

  TiketCategory({
    required this.id,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    required this.title,
    required this.price,
    required this.kuota,
    required this.status,
  });

  factory TiketCategory.fromJson(Map<String, dynamic> json) => TiketCategory(
        id: _parseInt(json['id']),
        badge: _parseString(json['badge']).trim(),
        badgeBg: _parseString(json['badge_bg'], fallback: '#fef3c7').trim(),
        badgeColor:
            _parseString(json['badge_color'], fallback: '#92400e').trim(),
        title: _parseString(json['title'], fallback: 'Tiket Museum').trim(),
        price: _parseInt(json['price']),
        kuota: _parseInt(json['kuota'], fallback: 500),
        status: _parseString(json['status'], fallback: 'Aktif').trim(),
      );
}

/// Model pemesanan tiket
class TicketBooking {
  final String id;
  final String nama;
  final String email;
  final String? phone;
  final int kategoriDewasa;
  final int kategoriPelajar;
  final int kategoriWna;
  final int totalTiket;
  final int totalBiaya;
  final String sesi;
  final String visitDate;
  final String paymentMethod;
  final String status;
  final int checkedIn;
  final int isMancanegara;

  TicketBooking({
    required this.id,
    required this.nama,
    required this.email,
    this.phone,
    required this.kategoriDewasa,
    required this.kategoriPelajar,
    required this.kategoriWna,
    required this.totalTiket,
    required this.totalBiaya,
    required this.sesi,
    required this.visitDate,
    required this.paymentMethod,
    required this.status,
    required this.checkedIn,
    this.isMancanegara = 0,
  });

  bool get isPaid => status.toUpperCase() == 'LUNAS';
  bool get isCancelled => status.toUpperCase() == 'BATAL';

  TicketBooking copyWith({
    String? status,
    int? checkedIn,
  }) =>
      TicketBooking(
        id: id,
        nama: nama,
        email: email,
        phone: phone,
        kategoriDewasa: kategoriDewasa,
        kategoriPelajar: kategoriPelajar,
        kategoriWna: kategoriWna,
        totalTiket: totalTiket,
        totalBiaya: totalBiaya,
        sesi: sesi,
        visitDate: visitDate,
        paymentMethod: paymentMethod,
        status: status ?? this.status,
        checkedIn: checkedIn ?? this.checkedIn,
        isMancanegara: isMancanegara,
      );

  factory TicketBooking.fromJson(Map<String, dynamic> json) {
    final rawPhone = _parseString(json['phone']).trim();
    return TicketBooking(
      id: _parseString(json['id']).trim(),
      nama: _parseString(json['nama'], fallback: 'Pengunjung').trim(),
      email: _parseString(json['email']).trim(),
      phone: rawPhone.isNotEmpty ? rawPhone : null,
      kategoriDewasa: _parseInt(json['kategori_dewasa']),
      kategoriPelajar: _parseInt(json['kategori_pelajar']),
      kategoriWna: _parseInt(json['kategori_wna']),
      totalTiket: _parseInt(json['total_tiket'], fallback: 1),
      totalBiaya: _parseInt(json['total_biaya']),
      sesi: _parseString(json['sesi'], fallback: '08:00 - 10:00').trim(),
      visitDate: _parseString(json['visit_date']).trim(),
      paymentMethod:
          _parseString(json['payment_method'], fallback: 'QRIS').trim(),
      status: _parseString(json['status'], fallback: 'MENUNGGU').trim(),
      checkedIn: _parseInt(json['checked_in']),
      isMancanegara: _parseInt(json['is_mancanegara']),
    );
  }
}

/// Hasil verifikasi status pembayaran Midtrans
class PaymentStatusResult {
  final String bookingStatus;
  final String transactionStatus;
  final String message;
  final TicketBooking? booking;
  final String? pdfUrl;
  final String? qrImageUrl;

  const PaymentStatusResult({
    required this.bookingStatus,
    required this.transactionStatus,
    required this.message,
    this.booking,
    this.pdfUrl,
    this.qrImageUrl,
  });

  bool get isPaid => bookingStatus.toUpperCase() == 'LUNAS';
  bool get isCancelled => bookingStatus.toUpperCase() == 'BATAL';
}
