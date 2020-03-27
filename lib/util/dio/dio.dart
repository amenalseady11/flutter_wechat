import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wechat/providers/profile/profile.dart';

/// 请求响应体
class DioResponse {
  /// 响应状态码
  int code;

  /// 响应提示消息
  String message;

  /// 是否请求成功
  bool get success => (code ?? 0) == 200;

  /// 响应体
  dynamic body;

  DioResponse({@required this.code, @required this.message, this.body});

  DioResponse.fromJson(Map<String, dynamic> json) {
    if (json["Code"] is int) this.code = json["Code"];
    if (json["Message"] is String) this.message = json["Message"];
    this.body = json["Body"];
  }

  static Future<DioResponse> from(Future<Response> response) {
    return response.then((response) => response.data);
  }
}

final Dio dio = Dio()
  ..interceptors.addAll([
    LogInterceptor(
      responseHeader: true,
      responseBody: true,
    ),
    InterceptorsWrapper(
      onRequest: (RequestOptions options) async {
        var authToken = ProfileProvider().authToken;
        // 如果已登录，带上已登录的签名令牌
        if (authToken != null) options.headers["AUTH_TOKEN"] = authToken;
        return options;
      },
      onResponse: (Response response) async {
        if (response.data is! Map) {
          response.data = DioResponse(code: 555, message: "服务已变更，请申请应用！");
          return response;
        }
        DioResponse rsp = DioResponse.fromJson(response.data);
        if (rsp.message == null) rsp.message = rsp.success ? "操作成功!" : "操作失败!";
        response.data = rsp;
        return response;
      },
      onError: (DioError error) async {
        if (error.response == null) error.response = new Response(data: {});
        var response = error?.response;
        var code = error?.response?.statusCode ?? 500;

        var message = error?.message ?? "服务繁忙，请稍后再试！";
        DioResponse rsp = DioResponse(code: code, message: message);

        if (response?.data is Map) {
          if (response?.data["Code"] is int) rsp.code = response?.data["Code"];
          if (response?.data["Message"] is String)
            rsp.message = response?.data["Message"];
          if (response?.data["Body"] != null) rsp.body = response?.data["Body"];
        }
        response.data = rsp;
        return response;
      },
    )
  ]);

void setDioConfiguration({
  @required String baseUrl,
  int connectTimeout,
  int receiveTimeout,
  String contentType,
}) {
  dio.options.baseUrl = baseUrl;
  dio.options.connectTimeout = connectTimeout ?? 1000 * 15; //5s
  dio.options.receiveTimeout = receiveTimeout ?? 1000 * 15;
  dio.options.contentType = contentType ?? Headers.jsonContentType;
}
