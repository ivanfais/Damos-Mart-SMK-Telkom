import 'package:equatable/equatable.dart';

class CooperativeInfoModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String infoType;
  final bool isActive;

  const CooperativeInfoModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.infoType,
    required this.isActive,
  });

  factory CooperativeInfoModel.fromJson(Map<String, dynamic> json) {
    return CooperativeInfoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      infoType: json['infoType'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'infoType': infoType,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [id, title, content, imageUrl, infoType, isActive];
}

class OperatingHourModel extends Equatable {
  final String id;
  final int dayOfWeek;
  final String? openTime;
  final String? closeTime;
  final bool isClosed;

  const OperatingHourModel({
    required this.id,
    required this.dayOfWeek,
    this.openTime,
    this.closeTime,
    required this.isClosed,
  });

  factory OperatingHourModel.fromJson(Map<String, dynamic> json) {
    return OperatingHourModel(
      id: json['id'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'openTime': openTime,
      'closeTime': closeTime,
      'isClosed': isClosed,
    };
  }

  @override
  List<Object?> get props => [id, dayOfWeek, openTime, closeTime, isClosed];
}

class CrowdDataModel extends Equatable {
  final String id;
  final int hourSlot;
  final int dayOfWeek;
  final int avgCrowdLevel;

  const CrowdDataModel({
    required this.id,
    required this.hourSlot,
    required this.dayOfWeek,
    required this.avgCrowdLevel,
  });

  factory CrowdDataModel.fromJson(Map<String, dynamic> json) {
    return CrowdDataModel(
      id: json['id'] as String,
      hourSlot: json['hourSlot'] as int,
      dayOfWeek: json['dayOfWeek'] as int,
      avgCrowdLevel: json['avgCrowdLevel'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hourSlot': hourSlot,
      'dayOfWeek': dayOfWeek,
      'avgCrowdLevel': avgCrowdLevel,
    };
  }

  @override
  List<Object?> get props => [id, hourSlot, dayOfWeek, avgCrowdLevel];
}

class CooperativeStatusModel extends Equatable {
  final String condition;

  const CooperativeStatusModel({required this.condition});

  factory CooperativeStatusModel.fromJson(Map<String, dynamic> json) {
    return CooperativeStatusModel(
      condition: (json['condition'] as String? ?? 'NORMAL').toUpperCase(),
    );
  }

  String get label {
    switch (condition) {
      case 'SEPI':
        return 'Sepi';
      case 'RAMAI':
        return 'Ramai';
      default:
        return 'Normal';
    }
  }

  @override
  List<Object?> get props => [condition];
}
