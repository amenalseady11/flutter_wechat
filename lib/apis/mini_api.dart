part of 'apis.dart';

Future<DioResponse> toGetMinisByPage(
    {@required int pageNo, int pageSize = 20}) {
  return dio.get("/mini/page", queryParameters: {
    "Page": pageNo,
    "PageSize": pageSize
  }).then((res) => res.data);
}
