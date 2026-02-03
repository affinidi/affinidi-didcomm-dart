import 'package:json_annotation/json_annotation.dart';

import '../../../didcomm.dart';
import '../../annotations/own_json_properties.dart';

@OwnJsonProperties()
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class VdipMessage extends PlainTextMessage {
  static final requestIssuanceMessageUri = Uri.parse(
      'https://affinidi.com/didcomm/protocols/vdip/1.0/request-issuance');
  static final identificationRequestMessageUri = Uri.parse(
      'https://affinidi.com/didcomm/protocols/vdip/1.0/identification-request');
  static final problemReportMessageUri =
      Uri.parse('https://didcomm.org/report-problem/2.0/problem-report');
  static final issuedCredentialMessageUri = Uri.parse(
      'https://affinidi.com/didcomm/protocols/vdip/1.0/issued-credential');
  static final acceptedCredentialMessageUri = Uri.parse(
      'https://affinidi.com/didcomm/protocols/vdip/1.0/credential-accepted');

  VdipMessage({
    required super.id,
    required super.from,
    required super.to,
    required super.createdTime,
    required super.expiresTime,
    required super.body,
    required super.type,
  });

  factory VdipMessage.requestIssuanceMessage({
    required String id,
    required String? from,
    required List<String> to,
    required DateTime? createdTime,
    required DateTime? expiresTime,
    required Map<String, dynamic>? body,
  }) =>
      VdipMessage(
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
    required List<String> to,
    required DateTime? createdTime,
    required DateTime? expiresTime,
    required Map<String, dynamic>? body,
  }) =>
      VdipMessage(
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
    required List<String> to,
    required DateTime? createdTime,
    required DateTime? expiresTime,
    required Map<String, dynamic>? body,
  }) =>
      VdipMessage(
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
    required List<String> to,
    required DateTime? createdTime,
    required DateTime? expiresTime,
    required Map<String, dynamic>? body,
  }) =>
      VdipMessage(
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
    required List<String> to,
    required DateTime? createdTime,
    required DateTime? expiresTime,
    required Map<String, dynamic>? body,
  }) =>
      VdipMessage(
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
