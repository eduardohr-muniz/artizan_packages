/// The primitive type of a parameter or header.
enum ParamType {
  /// A string of characters.
  string,

  /// An integer number.
  integer,

  /// A floating point number.
  number,

  /// A boolean value (true/false).
  boolean;

  /// The OpenAPI specification name for this type.
  String get openApiName => name;
}
