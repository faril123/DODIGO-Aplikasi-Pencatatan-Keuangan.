class TargetModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String status;
  final String? imageUrl;

  const TargetModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    this.imageUrl,
    this.status = 'berjalan',
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  bool get sudahTercapai => currentAmount >= targetAmount;
  bool get masihBerjalan => status == 'berjalan';

  factory TargetModel.fromJson(Map<String, dynamic> json) {
    return TargetModel(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      status: json['status'] as String? ?? 'berjalan',
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String().split('T').first,
      'image_url': imageUrl,
    };
  }
}
