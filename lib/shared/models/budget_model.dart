class BudgetModel {
  final String id;
  final String category;
  final double limitAmount;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.limitAmount,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      category: json['category'] as String,
      limitAmount: (json['limit_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toUpsertJson({required String userId}) {
    return {
      'user_id': userId,
      'category': category,
      'limit_amount': limitAmount,
    };
  }
}
