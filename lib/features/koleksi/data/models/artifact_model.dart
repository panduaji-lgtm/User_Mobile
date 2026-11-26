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
