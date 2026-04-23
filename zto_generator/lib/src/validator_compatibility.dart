/// Maps Zto field types to the set of validator names they accept.
///
/// Used by [DtoGenerator] to fail the build when a validator incompatible
/// with the field type is used (e.g. @ZEmail on @ZDouble).
const Map<String, Set<String>> validatorCompatibility = {
  'ZString': {
    'ZMinLength',
    'ZMaxLength',
    'ZLength',
    'ZEmail',
    'ZUuid',
    'ZUrl',
    'ZPattern',
    'ZStartsWith',
    'ZEndsWith',
    'ZIncludes',
    'ZBase64',
    'ZHex',
    'ZIpv4',
    'ZIpv6',
    'ZHttpUrl',
    'ZJwt',
    'ZIsoDate',
    'ZIsoDateTime',
    'ZUppercase',
    'ZLowercase',
    'ZSlug',
    'ZAlphanumeric',
  },
  'ZInt': {
    'ZMin',
    'ZMax',
    'ZPositive',
    'ZNegative',
    'ZMultipleOf',
    'ZInteger',
    'ZNonNegative',
    'ZNonPositive',
    'ZFinite',
    'ZSafeInt',
  },
  'ZDouble': {
    'ZMin',
    'ZMax',
    'ZPositive',
    'ZNegative',
    'ZMultipleOf',
    'ZInteger',
    'ZNonNegative',
    'ZNonPositive',
    'ZFinite',
    'ZSafeInt',
  },
  'ZNum': {
    'ZMin',
    'ZMax',
    'ZPositive',
    'ZNegative',
    'ZMultipleOf',
    'ZInteger',
    'ZNonNegative',
    'ZNonPositive',
    'ZFinite',
    'ZSafeInt',
  },
  'ZDate': {
    'ZMin',
    'ZMax',
  },
  'ZBool': {},
  'ZEnum': {},
  'ZFile': {},
  'ZList': {},
  'ZListOf': {},
  'ZObj': {},
  'ZMap': {},
  'ZMetaData': {},
  'ZObject': {},
};

/// Human-readable field types that [validatorName] applies to (for error messages).
String allowedFieldTypesForValidator(String validatorName) {
  if (_stringValidators.contains(validatorName)) return 'String';
  if (_numericValidators.contains(validatorName)) return 'numeric (ZInt, ZDouble, ZNum)';
  if (_dateValidators.contains(validatorName)) return 'Date';
  return 'compatible';
}

const _stringValidators = {
  'ZMinLength',
  'ZMaxLength',
  'ZLength',
  'ZEmail',
  'ZUuid',
  'ZUrl',
  'ZPattern',
  'ZStartsWith',
  'ZEndsWith',
  'ZIncludes',
  'ZBase64',
  'ZHex',
  'ZIpv4',
  'ZIpv6',
  'ZHttpUrl',
  'ZJwt',
  'ZIsoDate',
  'ZIsoDateTime',
  'ZUppercase',
  'ZLowercase',
  'ZSlug',
  'ZAlphanumeric',
};

const _numericValidators = {
  'ZMin',
  'ZMax',
  'ZPositive',
  'ZNegative',
  'ZMultipleOf',
  'ZInteger',
  'ZNonNegative',
  'ZNonPositive',
  'ZFinite',
  'ZSafeInt',
};

const _dateValidators = {'ZMin', 'ZMax'};
