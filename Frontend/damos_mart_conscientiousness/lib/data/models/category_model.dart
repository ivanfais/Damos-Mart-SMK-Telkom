import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final String? iconUrl;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'sortOrder': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, name, iconUrl, sortOrder];
}
