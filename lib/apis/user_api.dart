part of 'apis.dart';

/// 获取验证码
Future<DioResponse> toGetVerifySms({@required String mobile}) {
  return dio.post("/verify/sms",
      data: {"MobileNumber": mobile}).then((res) => res.data);
}

/// 登录注册二合一接口
Future<DioResponse> toLoginOrRegister(
    {@required String mobile, @required String captcha}) {
  return dio.post("/user/login", data: {
    "MobileNumber": mobile,
    "VerifyCode": captcha
  }).then((res) => res.data);
}

/// 1.3 更新昵称/头像
///
Future<DioResponse> toUpdateProfile({String nickname, String avatar}) {
  var data = {
    "NickName": nickname ?? global.profile.nickname,
    "Avatar": avatar ?? global.profile.avatar
  };
  return dio.put("/user/update", data: data).then((res) => res.data);
}

/// 7.1 对象存储接口
/// [file] 上传文件
/// [suffix] 后缀
Future<DioResponse> toUploadFile(File file,
    {MediaType contentType, String suffix}) {
  var uploadFile = MultipartFile.fromBytes(file.readAsBytesSync(),
      filename: file.path,
      contentType: contentType ?? MediaType("image", "png"));
  var formData = FormData.fromMap({"uploadFile": uploadFile});
  return dio
      .post("/project/upload/${suffix ?? uploadFile.contentType.subtype}",
          data: formData,
          options: RequestOptions(baseUrl: global.uploadBaseUrl))
      .then((res) => res.data);
}

/// 7.1 对象存储接口
/// [file] 上传文件
/// [suffix] 后缀
Future<DioResponse> toUploadFile2(MultipartFile uploadFile, {String suffix}) {
  var formData = FormData.fromMap({"uploadFile": uploadFile});
  return dio
      .post("/project/upload/${suffix ?? uploadFile.contentType.subtype}",
          data: formData,
          options: RequestOptions(baseUrl: global.uploadBaseUrl))
      .then((res) => res.data);
}
