class BillModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final bool isRecurring;
  final int? recurringTotalMonths;
  final int recurringOccurrence;

  const BillModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    required this.isRecurring,
    this.recurringTotalMonths,
    this.recurringOccurrence = 1,
  });

  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    final hariIni = DateTime(now.year, now.month, now.day);
    final jatuhTempo = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return jatuhTempo.isBefore(hariIni);
  }

  bool get masihAdaLanjutan =>
      recurringTotalMonths == null ||
      recurringOccurrence < recurringTotalMonths!;

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      isPaid: json['is_paid'] as bool,
      isRecurring: json['is_recurring'] as bool,
      recurringTotalMonths: json['recurring_total_months'] as int?,
      recurringOccurrence: json['recurring_occurrence'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'title': title,
      'category': category,
      'amount': amount,
      'due_date': dueDate.toIso8601String().split('T').first,
      'is_paid': isPaid,
      'is_recurring': isRecurring,
      'recurring_total_months': recurringTotalMonths,
      'recurring_occurrence': recurringOccurrence,
    };
  }
}
