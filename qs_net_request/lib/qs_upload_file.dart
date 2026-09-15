/// 待上传文件
class QsUploadFile {
  const QsUploadFile({
    required this.fieldName,
    required this.filePath,
    this.fileName,
  });

  /// Property
  /// 表单字段名
  final String fieldName;

  /// 本地文件路径
  final String filePath;

  /// 上传文件名，未设置时使用本地文件名
  final String? fileName;
}
