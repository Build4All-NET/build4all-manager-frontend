class CountryModel {
  final int id;
  final String name;
  final String iso2Code;

  const CountryModel({
    required this.id,
    required this.name,
    required this.iso2Code,
  });

  factory CountryModel.fromJson(Map<String, dynamic> j) {
    return CountryModel(
      id: (j['id'] as num).toInt(),
      name: (j['name'] ?? '').toString(),
      iso2Code: (j['iso2Code'] ?? '').toString(),
    );
  }
}
