String formatRupiah(double value) {
  final isNegatif = value < 0;
  final absValue = value.abs().toStringAsFixed(0);
  final withDots = absValue.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '${isNegatif ? '-' : ''}Rp$withDots';
}

DateTime tambahBulan(DateTime date, int bulan) {
  final totalBulan = date.month - 1 + bulan;
  final tahunBaru = date.year + totalBulan ~/ 12;
  final bulanBaru = totalBulan % 12 + 1;
  final hariTerakhirBulan = DateTime(tahunBaru, bulanBaru + 1, 0).day;
  final tanggalAman = date.day > hariTerakhirBulan
      ? hariTerakhirBulan
      : date.day;
  return DateTime(tahunBaru, bulanBaru, tanggalAman);
}
