enum MediatorServiceType {
  didCommMessaging('DIDCommMessaging'),
  authentication('Authentication');

  final String value;
  const MediatorServiceType(this.value);
}
