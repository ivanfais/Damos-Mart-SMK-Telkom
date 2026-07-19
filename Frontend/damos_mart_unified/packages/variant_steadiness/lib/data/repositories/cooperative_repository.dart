import '../../config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../models/cooperative_info_model.dart';

class CooperativeRepository {
  final DioClient _client;

  CooperativeRepository({DioClient? client}) : _client = client ?? DioClient.instance;

  Future<List<OperatingHourModel>> getOperatingHours() async {
    final response = await _client.get(ApiConfig.operatingHours);
    final dataList = response.data['data'] as List? ?? [];
    return dataList
        .map((json) => OperatingHourModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CrowdDataModel>> getCrowdData() async {
    final response = await _client.get(ApiConfig.crowdData);
    final dataList = response.data['data'] as List? ?? [];
    return dataList
        .map((json) => CrowdDataModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<CooperativeInfoModel>> getCooperativeInfo() async {
    final response = await _client.get(ApiConfig.cooperativeInfo);
    final dataList = response.data['data'] as List? ?? [];
    return dataList
        .map((json) => CooperativeInfoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CooperativeStatusModel> getCurrentStatus() async {
    final response = await _client.get(ApiConfig.cooperativeStatus);
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return CooperativeStatusModel.fromJson(data);
  }
}
