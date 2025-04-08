
class Cart {
  final String id;
  final String name;
  final String operator;
  final String description;
  final bool isActive;

  Cart({
    required this.id,
    required this.name,
    required this.operator,
    this.description = '',
    this.isActive = true,
  });

  // Convertir en Map pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'operator': operator,
      'description': description,
      'isActive': isActive,
    };
  }

  // Créer un objet Cart à partir d'un Map
  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      name: json['name'],
      operator: json['operator'],
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  // Créer une copie avec des valeurs modifiées
  Cart copyWith({
    String? id,
    String? name,
    String? operator,
    String? description,
    bool? isActive,
  }) {
    return Cart(
      id: id ?? this.id,
      name: name ?? this.name,
      operator: operator ?? this.operator,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Cart{id: $id, name: $name, operator: $operator, isActive: $isActive}';
  }
}