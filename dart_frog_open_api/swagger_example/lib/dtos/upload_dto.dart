import 'package:zto/zto.dart';

part 'upload_dto.g.dart';

/// Request DTO for multipart/form-data file uploads.
@ZDto(description: 'File upload request', parseType: ParseType.snakeCase)
class UploadRequestDto {
  @ZFile(description: 'Binary file to upload (any MIME type)')
  final dynamic file;

  @ZString(
    description: 'Optional display name for the stored file',
    example: 'avatar.png',
  )
  final String? displayName;

  const UploadRequestDto({required this.file, this.displayName});

  factory UploadRequestDto.fromMap(Map<String, dynamic> map) => UploadRequestDto(
        file: map['file'],
        displayName: map['display_name'] as String?,
      );
}

/// Response DTO returned after a successful file upload.
@ZDto(description: 'Upload response', parseType: ParseType.snakeCase)
class UploadResponseDto {
  @ZString(description: 'Stored file name', example: 'avatar.png')
  final String fileName;

  @ZInt(description: 'File size in bytes', example: 102400)
  final int size;

  @ZString(
    description: 'MIME type of the uploaded file',
    example: 'image/png',
  )
  final String mimeType;

  const UploadResponseDto({
    required this.fileName,
    required this.size,
    required this.mimeType,
  });
}
