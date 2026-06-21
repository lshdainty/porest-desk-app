/// 구독·기능권한·토스 크리덴셜 repository. 증권 메뉴 게이트 + 설정(토스 연결) 백엔드 연동.
/// Dio baseUrl 이 이미 /api/v1 이므로 경로는 /users/me/features, /subscriptions, /users/me/toss-credential.
library;

import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';

class MyFeatures {
  const MyFeatures({required this.features, required this.tossConnected});
  final List<String> features;
  final bool tossConnected;

  bool get hasSecurities => features.contains('SECURITIES');

  factory MyFeatures.fromJson(Map<String, dynamic> j) => MyFeatures(
        features: ((j['features'] as List?) ?? []).map((e) => e.toString()).toList(),
        tossConnected: (j['tossConnected'] as bool?) ?? false,
      );

  static const empty = MyFeatures(features: [], tossConnected: false);
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.planCode,
    required this.planName,
    required this.status,
    this.currentPeriodEnd,
    required this.autoRenew,
  });
  final String planCode;
  final String planName;
  final String status;
  final String? currentPeriodEnd;
  final bool autoRenew;

  bool get isActive => status == 'ACTIVE';

  factory SubscriptionInfo.fromJson(Map<String, dynamic> j) => SubscriptionInfo(
        planCode: j['planCode'] as String,
        planName: j['planName'] as String,
        status: j['status'] as String,
        currentPeriodEnd: j['currentPeriodEnd'] as String?,
        autoRenew: (j['autoRenew'] as bool?) ?? false,
      );
}

class SubscriptionPlanInfo {
  const SubscriptionPlanInfo({required this.planCode, required this.planName, this.durationMonths});
  final String planCode;
  final String planName;
  final int? durationMonths;

  factory SubscriptionPlanInfo.fromJson(Map<String, dynamic> j) => SubscriptionPlanInfo(
        planCode: j['planCode'] as String,
        planName: j['planName'] as String,
        durationMonths: j['durationMonths'] as int?,
      );
}

class TossCredentialStatus {
  const TossCredentialStatus({required this.connected, required this.verified, this.verifiedAt});
  final bool connected;
  final bool verified;
  final String? verifiedAt;

  factory TossCredentialStatus.fromJson(Map<String, dynamic> j) => TossCredentialStatus(
        connected: (j['connected'] as bool?) ?? false,
        verified: (j['verified'] as bool?) ?? false,
        verifiedAt: j['verifiedAt'] as String?,
      );

  static const notConnected = TossCredentialStatus(connected: false, verified: false);
}

class SubscriptionRepository {
  SubscriptionRepository(this._dio);
  final Dio _dio;

  dynamic _payload(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic>) return body['data'];
    return body;
  }

  Future<MyFeatures> getMyFeatures() async {
    try {
      final res = await _dio.get<dynamic>('/users/me/features');
      final p = _payload(res);
      return p is Map<String, dynamic> ? MyFeatures.fromJson(p) : MyFeatures.empty;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<SubscriptionPlanInfo>> getPlans() async {
    try {
      final res = await _dio.get<dynamic>('/subscriptions/plans');
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => SubscriptionPlanInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<SubscriptionInfo?> getMySubscription() async {
    try {
      final res = await _dio.get<dynamic>('/subscriptions/me');
      final p = _payload(res);
      return p is Map<String, dynamic> ? SubscriptionInfo.fromJson(p) : null;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> subscribe(String planCode) async {
    try {
      await _dio.post<dynamic>('/subscriptions', data: {'planCode': planCode});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cancelSubscription({String? reason}) async {
    try {
      await _dio.delete<dynamic>('/subscriptions/me', data: {'reason': reason});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TossCredentialStatus> getTossCredentialStatus() async {
    try {
      final res = await _dio.get<dynamic>('/users/me/toss-credential');
      final p = _payload(res);
      return p is Map<String, dynamic> ? TossCredentialStatus.fromJson(p) : TossCredentialStatus.notConnected;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> registerTossCredential(String clientId, String clientSecret) async {
    try {
      await _dio.post<dynamic>('/users/me/toss-credential',
          data: {'clientId': clientId, 'clientSecret': clientSecret});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> disconnectTossCredential() async {
    try {
      await _dio.delete<dynamic>('/users/me/toss-credential');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
