class UnsupportedCurveError extends UnsupportedError {
  UnsupportedCurveError(String curve) : super('$curve is not supported');
}
