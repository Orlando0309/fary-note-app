
class Stock {
  final String id;
  final DateTime arrivalDate;
  final double quantity; // en kg
  final double purchasePrice;
  final String supplier;
  final String notes;

  Stock({
    required this.id,
    required this.arrivalDate,
    required this.quantity,
    required this.purchasePrice,
    this.supplier = '',
    this.notes = '',
  });

  // Convertir en Map pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arrivalDate': arrivalDate.millisecondsSinceEpoch,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'supplier': supplier,
      'notes': notes,
    };
  }

  // Créer un objet Stock à partir d'un Map
  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      arrivalDate: DateTime.fromMillisecondsSinceEpoch(json['arrivalDate']),
      quantity: json['quantity'].toDouble(),
      purchasePrice: json['purchasePrice'].toDouble(),
      supplier: json['supplier'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  // Créer une copie avec des valeurs modifiées
  Stock copyWith({
    String? id,
    DateTime? arrivalDate,
    double? quantity,
    double? purchasePrice,
    String? supplier,
    String? notes,
  }) {
    return Stock(
      id: id ?? this.id,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Stock{id: $id, arrivalDate: $arrivalDate, quantity: $quantity kg, purchasePrice: $purchasePrice}';
  }
}