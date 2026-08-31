/// 구독·기능권한·증권사 크리덴셜 repository. 증권 메뉴 게이트 + 설정(증권사 연결) 백엔드 연동.
/// Dio baseUrl 이 이미 /api/v1 이므로 경로는 /users/me/features, /subscriptions,
/// /users/me/securities-credentials.
library;

import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';

class MyFeatures {
  const MyFeatures({
    required this.features,
    required this.connectedBrokers,
    this.primaryBroker,
  });
  final List<String> features;

  /// 연결된 증권사 코드. 증권사가 늘어도 이 목록만 늘어난다.
  final List<String> connectedBrokers;

  /// 가계부 자산 평가에 쓰는 증권사. 연결이 없으면 null.
  final String? primaryBroker;

  bool get hasSecurities => features.contains('SECURITIES');

  /// 증권사를 가리지 않고 하나라도 연결됐는지 — 증권 화면·자산 연동 노출 판정.
  bool get hasBrokerConnection => connectedBrokers.isNotEmpty;

  bool isConnected(String broker) => connectedBrokers.contains(broker);

  factory MyFeatures.fromJson(Map<String, dynamic> j) {
    final brokers = ((j['connectedBrokers'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    return MyFeatures(
      features: ((j['features'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      // 구버전 서버는 connectedBrokers 를 안 준다 — tossConnected 로 되살린다.
      connectedBrokers: brokers.isNotEmpty
          ? brokers
          : ((j['tossConnected'] as bool?) ?? false
                ? const ['TOSS']
                : const []),
      primaryBroker: j['primaryBroker'] as String?,
    );
  }

  static const empty = MyFeatures(features: [], connectedBrokers: []);
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
  const SubscriptionPlanInfo({
    required this.planCode,
    required this.planName,
    this.durationMonths,
  });
  final String planCode;
  final String planName;
  final int? durationMonths;

  factory SubscriptionPlanInfo.fromJson(Map<String, dynamic> j) =>
      SubscriptionPlanInfo(
        planCode: j['planCode'] as String,
        planName: j['planName'] as String,
        durationMonths: j['durationMonths'] as int?,
      );
}

/// 증권사 한 곳의 연결 상태 + 입력 폼 라벨.
///
/// 표시명·발급처·라벨을 **서버가 준다.** 증권사가 늘어도 앱 배포 없이 목록에 나타나고,
/// 같은 자리를 회사마다 다르게 부르는 문제(토스 Client ID / 나무 App Key)도 여기서 풀린다.
class BrokerConnection {
  const BrokerConnection({
    required this.broker,
    required this.displayName,
    required this.issueUrl,
    required this.keyLabel,
    required this.secretLabel,
    required this.connected,
    required this.verified,
    required this.primary,
    this.verifiedAt,
  });

  final String broker;
  final String displayName;
  final String issueUrl;
  final String keyLabel;
  final String secretLabel;
  final bool connected;
  final bool verified;
  final bool primary;
  final String? verifiedAt;

  factory BrokerConnection.fromJson(Map<String, dynamic> j) => BrokerConnection(
    broker: (j['broker'] as String?) ?? '',
    displayName: (j['displayName'] as String?) ?? '',
    issueUrl: (j['issueUrl'] as String?) ?? '',
    keyLabel: (j['keyLabel'] as String?) ?? 'API Key',
    secretLabel: (j['secretLabel'] as String?) ?? 'API Secret',
    connected: (j['connected'] as bool?) ?? false,
    verified: (j['verified'] as bool?) ?? false,
    primary: (j['primary'] as bool?) ?? false,
    verifiedAt: j['verifiedAt'] as String?,
  );
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
      return p is Map<String, dynamic>
          ? MyFeatures.fromJson(p)
          : MyFeatures.empty;
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

  /// 전 증권사 연결 상태. **미연결 증권사도 포함**해 화면이 목록을 그린다.
  Future<List<BrokerConnection>> getBrokerConnections() async {
    try {
      final res = await _dio.get<dynamic>('/users/me/securities-credentials');
      final p = _payload(res);
      if (p is! List) return const [];
      return p
          .whereType<Map<String, dynamic>>()
          .map(BrokerConnection.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> registerBrokerCredential(
    String broker,
    String apiKey,
    String apiSecret,
  ) async {
    try {
      await _dio.post<dynamic>(
        '/users/me/securities-credentials/$broker',
        data: {'apiKey': apiKey, 'apiSecret': apiSecret},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> disconnectBrokerCredential(String broker) async {
    try {
      await _dio.delete<dynamic>('/users/me/securities-credentials/$broker');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 가계부 자산 평가에 쓸 증권사를 지정한다.
  Future<void> setPrimaryBroker(String broker) async {
    try {
      await _dio.put<dynamic>(
        '/users/me/securities-credentials/$broker/primary',
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
