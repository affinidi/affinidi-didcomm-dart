import 'package:didcomm/src/annotations/own_json_properties.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:ssi/ssi.dart';
import '../didcomm_message.dart';
import '../recipients/recipient.dart';

part 'encrypted_message.g.dart';
part 'encrypted_message.own_json_props.g.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false)
class EncryptedMessage extends DidcommMessage {
  @override
  String get mediaType => 'application/didcomm-encrypted+json';

  @JsonKey(name: 'ciphertext')
  final String cipherText;

  final String protected;
  final List<Recipient> recipients;
  final String tag;

  @JsonKey(name: 'iv')
  final String initializationVector;

  EncryptedMessage({
    required this.cipherText,
    required this.protected,
    required this.recipients,
    required this.tag,
    required this.initializationVector,
  });

  factory EncryptedMessage.fromMessage(
    DidcommMessage message, {
    required Wallet wallet,
    required String walletKeyId,
    required List<Jwk> recipientPublicKeyJwks,
  }) {
    return EncryptedMessage(
      cipherText: '',
      protected: '',
      recipients: [],
      tag: '',
      initializationVector: '',
    );
  }

  factory EncryptedMessage.fromJson(Map<String, dynamic> json) {
    final message = _$EncryptedMessageFromJson(json)
      ..assignCustomHeaders(json, _$ownJsonProperties);

    return message;
  }

  Map<String, dynamic> toJson() =>
      withCustomHeaders(_$EncryptedMessageToJson(this));
}
