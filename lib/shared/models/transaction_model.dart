class TransactionModel {
  final String id;
  final String title;
  final String category;
  final String walletId;
  final double amount;
  final DateTime transactionDate;
  final String? imageUrl;

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'category': category,
      'wallet_id': walletId,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'image_url': imageUrl,
    };
  }

  const TransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.walletId,
    required this.amount,
    required this.transactionDate,
    this.imageUrl,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      walletId: json['wallet_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'title': title,
      'category': category,
      'wallet_id': walletId,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String().split('T').first,
      'image_url': imageUrl,
    };
  }
}
