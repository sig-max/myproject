class ExpenseModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String notes;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.notes,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['date'] ?? json['created_at'] ?? '').toString();
    return ExpenseModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['description'] ?? '').toString(),
      category: (json['category'] ?? 'General').toString(),
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0,
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      notes: (json['notes'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String().split('T')[0],
        'notes': notes,
      };
}
