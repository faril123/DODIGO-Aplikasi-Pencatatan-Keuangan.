class NotificationSettingsModel {
  final bool reminderCatatAktif;
  final bool reminderTagihanAktif;
  final bool reminderNabungAktif;
  final bool reminderBudgetAktif;

  const NotificationSettingsModel({
    this.reminderCatatAktif = true,
    this.reminderTagihanAktif = false,
    this.reminderNabungAktif = false,
    this.reminderBudgetAktif = false,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      reminderCatatAktif: json['reminder_catat_aktif'] as bool? ?? true,
      reminderTagihanAktif: json['reminder_tagihan_aktif'] as bool? ?? false,
      reminderNabungAktif: json['reminder_nabung_aktif'] as bool? ?? false,
      reminderBudgetAktif: json['reminder_budget_aktif'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toUpsertJson({required String userId}) {
    return {
      'user_id': userId,
      'reminder_catat_aktif': reminderCatatAktif,
      'reminder_tagihan_aktif': reminderTagihanAktif,
      'reminder_nabung_aktif': reminderNabungAktif,
      'reminder_budget_aktif': reminderBudgetAktif,
    };
  }

  NotificationSettingsModel copyWith({
    bool? reminderCatatAktif,
    bool? reminderTagihanAktif,
    bool? reminderNabungAktif,
    bool? reminderBudgetAktif,
  }) {
    return NotificationSettingsModel(
      reminderCatatAktif: reminderCatatAktif ?? this.reminderCatatAktif,
      reminderTagihanAktif: reminderTagihanAktif ?? this.reminderTagihanAktif,
      reminderNabungAktif: reminderNabungAktif ?? this.reminderNabungAktif,
      reminderBudgetAktif: reminderBudgetAktif ?? this.reminderBudgetAktif,
    );
  }
}
