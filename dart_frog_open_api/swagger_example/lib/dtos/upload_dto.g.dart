// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_dto.dart';

// **************************************************************************
// ZDtoGenerator
// **************************************************************************

const $UploadRequestDtoSchema = ZtoSchema(
  typeName: 'UploadRequestDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZFile(
          mapKey: 'file', description: 'Binary file to upload (any MIME type)'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'display_name',
          description: 'Optional display name for the stored file',
          example: 'avatar.png'),
      validators: [],
      isNullable: true,
    ),
  ],
);
final _ztoRegUploadRequestDto =
    Zto.registerSchema(UploadRequestDto.fromMap, $UploadRequestDtoSchema);
final _ztoRegTypeUploadRequestDto =
    Zto.registerSchema(UploadRequestDto, $UploadRequestDtoSchema);

const $UploadResponseDtoSchema = ZtoSchema(
  typeName: 'UploadResponseDto',
  descriptors: [
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'file_name',
          description: 'Stored file name',
          example: 'avatar.png'),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZInt(
          mapKey: 'size', description: 'File size in bytes', example: 102400),
      validators: [],
      isNullable: false,
    ),
    FieldDescriptor(
      fieldAnnotation: ZString(
          mapKey: 'mime_type',
          description: 'MIME type of the uploaded file',
          example: 'image/png'),
      validators: [],
      isNullable: false,
    ),
  ],
);
