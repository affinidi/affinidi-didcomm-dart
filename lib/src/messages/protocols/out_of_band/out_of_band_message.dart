import '../../didcomm_message.dart';
import 'package:json_annotation/json_annotation.dart';

part 'out_of_band_message.g.dart';

@JsonSerializable()
class OutOfBandMessage extends DidcommMessage {
  OutOfBandMessage();

  factory OutOfBandMessage.fromJson(Map<String, dynamic> json) =>
      _$OutOfBandMessageFromJson(json);

  Map<String, dynamic> toJson() => _$OutOfBandMessageToJson(this);
}
