class AdminDashboardData {
  const AdminDashboardData({
    required this.kpis,
    required this.userDistribution,
    required this.orderStatus,
    required this.topRestaurants,
  });
  final Map<String, dynamic> kpis;
  final List<Map<String, dynamic>> userDistribution;
  final List<Map<String, dynamic>> orderStatus;
  final List<Map<String, dynamic>> topRestaurants;
  factory AdminDashboardData.fromJson(Map<String, dynamic> json) =>
      AdminDashboardData(
        kpis: Map<String, dynamic>.from(json['kpis'] as Map? ?? const {}),
        userDistribution: _maps(json['userDistribution']),
        orderStatus: _maps(json['orderStatusDistribution']),
        topRestaurants: _maps(json['topRestaurants']),
      );
}

class AdminAnalyticsData {
  const AdminAnalyticsData({
    required this.salesTrend,
    required this.userGrowth,
    required this.orderStatus,
    required this.sales,
  });
  final List<Map<String, dynamic>> salesTrend, userGrowth, orderStatus;
  final Map<String, dynamic> sales;
  factory AdminAnalyticsData.fromJson(Map<String, dynamic> json) =>
      AdminAnalyticsData(
        salesTrend: _maps(json['salesTrend']),
        userGrowth: _maps(json['userGrowth']),
        orderStatus: _maps(json['orderStatusDistribution']),
        sales: Map<String, dynamic>.from(json['sales'] as Map? ?? const {}),
      );
}

class AdminApplication {
  const AdminApplication(this.data);
  final Map<String, dynamic> data;
  String get id => data['_id'] as String? ?? '';
  String get name => data['name'] as String? ?? 'Applicant';
  String get email => data['email'] as String? ?? '';
  String get role => data['role'] as String? ?? '';
  String get status => data['accountStatus'] as String? ?? '';
  bool get emailVerified => data['isEmailVerified'] == true;
}

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : [];
