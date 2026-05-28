import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class BillingTab extends Equatable {
  final String id;
  final String name;
  final List<ItemKeranjang> items;
  final DateTime createdAt;

  const BillingTab({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  double get totalAmount =>
      items.fold<double>(0, (sum, item) => sum + item.totalHarga);

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.jumlah);

  BillingTab copyWith({
    String? id,
    String? name,
    List<ItemKeranjang>? items,
    DateTime? createdAt,
  }) {
    return BillingTab(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object> get props => [id, name, items, createdAt];
}
