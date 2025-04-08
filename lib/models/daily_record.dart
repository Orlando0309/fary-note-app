
class DailyRecord {
  final String id;
  final DateTime date;
  final String cartId;
  final double assignedQuantity; // en kg
  final double soldQuantity; // en kg
  final double amountCollected; // argent versé
  final String remarks;

  DailyRecord({
    required this.id,
    required this.date,
    required this.cartId,
    required this.assignedQuantity,
    required this.soldQuantity,
    required this.amountCollected,
    this.remarks = '',
  });

  // Convertir en Map pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'cartId': cartId,
      'assignedQuantity': assignedQuantity,
      'soldQuantity': soldQuantity,
      'amountCollected': amountCollected,
      'remarks': remarks,
    };
  }

  // Créer un objet DailyRecord à partir d'un Map
  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      id: json['id'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      cartId: json['cartId'],
      assignedQuantity: json['assignedQuantity'].toDouble(),
      soldQuantity: json['soldQuantity'].toDouble(),
      amountCollected: json['amountCollected'].toDouble(),
      remarks: json['remarks'] ?? '',
    );
  }

  // Créer une copie avec des valeurs modifiées
  DailyRecord copyWith({
    String? id,
    DateTime? date,
    String? cartId,
    double? assignedQuantity,
    double? soldQuantity,
    double? amountCollected,
    String? remarks,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      cartId: cartId ?? this.cartId,
      assignedQuantity: assignedQuantity ?? this.assignedQuantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      amountCollected: amountCollected ?? this.amountCollected,
      remarks: remarks ?? this.remarks,
    );
  }

  @override
  String toString() {
    return 'DailyRecord{id: $id, date: $date, cartId: $cartId, assignedQuantity: $assignedQuantity kg, soldQuantity: $soldQuantity kg, amountCollected: $amountCollected}';
  }
}