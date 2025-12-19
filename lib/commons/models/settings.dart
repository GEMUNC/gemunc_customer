import 'package:eshop_plus/commons/models/systemSettings.dart';

class Settings {
  final String? logo;
  final String? privacyPolicy;
  final String? termsAndConditions;
  final String? contactUs;
  final String? aboutUs;
  final String? currency;
  final SystemSettings? systemSettings;
  final String? shippingPolicy;
  final String? returnPolicy;
  final PusherSettings? pusherSettings;
  final List<AdminPreference>? adminPreference;

  Settings(
      {this.aboutUs,
      this.contactUs,
      this.currency,
      this.logo,
      this.privacyPolicy,
      this.termsAndConditions,
      this.systemSettings,
      this.returnPolicy,
      this.shippingPolicy,
      this.pusherSettings,
      this.adminPreference});

  static Settings fromJson(Map<String, dynamic> json) {
    return Settings(
      aboutUs: ((json['about_us'] ?? [""]) as List)
          .map((e) => (e ?? "").toString())
          .first,
      contactUs: ((json['contact_us'] ?? [""]) as List)
          .map((e) => (e ?? "").toString())
          .first,
      currency: json['currency'] as String?,
      logo: ((json['logo'] ?? [""]) as List)
          .map((e) => (e ?? "").toString())
          .first,
      privacyPolicy: ((json['privacy_policy'] ?? [""]) as List)
          .map((e) => (e ?? "").toString())
          .first,
      termsAndConditions: ((json['terms_and_conditions'] ?? [""]) as List)
          .map((e) => (e ?? "").toString())
          .first,
      systemSettings:
          SystemSettings.fromJson((json['system_settings'] ?? [{}]).first),
      returnPolicy: ((json['return_policy'] ?? [""]) as List)
          .map((e) => (e ?? "").toString())
          .first,
      shippingPolicy: ((json['shipping_policy'] ?? [""]) as List)
          .map((e) => (e ?? "").toString())
          .first,
      pusherSettings: json['pusher_settings'] != null
          ? PusherSettings.fromJson((json['pusher_settings'] ?? [{}]).first)
          : PusherSettings(),
      adminPreference:
          json['admin_preference']!=null? (json['admin_preference'] as List?)
          ?.map((e) => AdminPreference.fromJson(e))
          .toList():null,
    );
  }
}

class PusherSettings {
  String? pusherAppCluster;
  String? pusherScheme;
  String? pusherPort;
  String? pusherAppSecret;
  String? pusherAppKey;
  String? pusherAppId;
  String? pusherChannelName;

  PusherSettings(
      {this.pusherAppCluster,
      this.pusherScheme,
      this.pusherPort,
      this.pusherAppSecret,
      this.pusherAppKey,
      this.pusherAppId,
      this.pusherChannelName});

  PusherSettings.fromJson(Map<String, dynamic> json) {
    pusherAppCluster = json['pusher_app_cluster'];
    pusherScheme = json['pusher_scheme'];
    pusherPort = json['pusher_port'];
    pusherAppSecret = json['pusher_app_secret'];
    pusherAppKey = json['pusher_app_key'];
    pusherAppId = json['pusher_app_id'];
    pusherChannelName = json['pusher_channel_name'];
  }
}

class AdminPreference {
  final String? storeMode;
  final int? orderNotification;

  AdminPreference({
    this.storeMode,
    this.orderNotification,
  });

  factory AdminPreference.fromJson(Map<String, dynamic> json) {
    return AdminPreference(
      storeMode: json['store_mode'] as String?,
      orderNotification: json['order_notification'] as int?,
    );
  }
}
