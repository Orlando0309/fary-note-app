
class Expense {
  final String id;
  final DateTime date;
  final double amount;
  final String category;
  final String description;

  Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    this.description = '',
  });

  // Convertir en Map pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'amount': amount,
      'category': category,
      'description': description,
    };
  }

  // Créer un objet Expense à partir d'un Map
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      amount: json['amount'].toDouble(),
      category: json['category'],
      description: json['description'] ?? '',
    );
  }

  // Créer une copie avec des valeurs modifiées
  Expense copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? category,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Expense{id: $id, date: $date, amount: $amount, category: $category}';
  }

  // Catégories prédéfinies de dépenses
  static List<String> categories = [
    'Achat de canne',
    'Maintenance',
    'Salaires',
    'Transport',
    'Loyer',
    'électricité',
    'Eau',
    'Autre',
  ];
}