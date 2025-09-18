import 'package:json_annotation/json_annotation.dart';

import '../../core/plain_text_message/plain_text_message.dart';
import '../../annotations/own_json_properties.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VdipMessage extends PlainTextMessage {

  static const requestIssuanceMessageUri = Uri.parse('https://affinidi.com/didcomm/protocols/vdip/1.0/request-issuance');
  static const identificationRequestMessageUri = Uri.parse('https://affinidi.com/didcomm/protocols/vdip/1.0/identification-request');
  static const problemReportMessageUri = Uri.parse('https://didcomm.org/report-problem/2.0/problem-report');
  static const issuedCredentialMessageUri = Uri.parse('https://affinidi.com/didcomm/protocols/vdip/1.0/issued-credential');
  static const acceptedCredentialMessageUri = Uri.parse('https://affinidi.com/didcomm/protocols/vdip/1.0/credential-accepted');

  VdipMessage({
    required super.id,
    required super.from,
    super.to,
    super.createdTime,
    super.expiresTime,
    super.body,
    required super.type,
  });

  factory VdipMessage.requestIssuanceMessage({
    required String id,
    required String? from,
    String? to,
    DateTime? createdTime,
    DateTime? expiresTime,
    Map<String, dynamic>? body,
  }) => VdipMessage(
        id: id,
        from: from,
        to: to,
        createdTime: createdTime,
        expiresTime: expiresTime,
        body: body,
        type: VdipMessage.requestIssuanceMessageUri,
      );

  factory VdipMessage.identificationRequestMessage({
    required String id,
    required String? from,
    String? to,
    DateTime? createdTime,
    DateTime? expiresTime,
    Map<String, dynamic>? body,
  }) => VdipMessage(
        id: id,
        from: from,
        to: to,
        createdTime: createdTime,
        expiresTime: expiresTime,
        body: body,
        type: VdipMessage.identificationRequestMessageUri,
      );

  factory VdipMessage.problemReportMessage({
    required String id,
    required String? from,
    String? to,
    DateTime? createdTime,
    DateTime? expiresTime,
    Map<String, dynamic>? body,
  }) => VdipMessage(
        id: id,
        from: from,
        to: to,
        createdTime: createdTime,
        expiresTime: expiresTime,
        body: body,
        type: VdipMessage.problemReportMessageUri,
      );

  factory VdipMessage.issuedCredentialMessage({
    required String id,
    required String? from,
    String? to,
    DateTime? createdTime,
    DateTime? expiresTime,
    Map<String, dynamic>? body,
  }) => VdipMessage(
        id: id,
        from: from,
        to: to,
        createdTime: createdTime,
        expiresTime: expiresTime,
        body: body,
        type: VdipMessage.issuedCredentialMessageUri,
      );

  factory VdipMessage.acceptedCredentialMessage({
    required String id,
    required String? from,
    String? to,
    DateTime? createdTime,
    DateTime? expiresTime,
    Map<String, dynamic>? body,
  }) => VdipMessage(
        id: id,
        from: from,
        to: to,
        createdTime: createdTime,
        expiresTime: expiresTime,
        body: body,
        type: VdipMessage.acceptedCredentialMessageUri,
      );

  bool isRequestIssuanceMessage() {
    return type == VdipMessage.requestIssuanceMessageUri;
  }

  bool isIdentificationRequestMessage() {
    return type == VdipMessage.identificationRequestMessageUri;
  }

  bool isProblemReportMessage() {
    return type == VdipMessage.problemReportMessageUri;
  }

  bool isIssuedCredentialMessage() {
    return type == VdipMessage.issuedCredentialMessageUri;
  }

  bool isAcceptedCredentialMessage() {
    return type == VdipMessage.acceptedCredentialMessageUri;
  }
}