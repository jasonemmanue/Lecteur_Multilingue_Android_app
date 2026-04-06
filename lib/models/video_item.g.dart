
part of 'video_item.dart';

class VideoItemAdapter extends TypeAdapter<VideoItem> {
  @override
  final int typeId = 0;

  @override
  VideoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoItem(
      id: fields[0] as String,
      title: fields[1] as String,
      localPath: fields[2] as String,
      thumbnailPath: fields[3] as String?,
      durationMs: fields[4] as int?,
      importedAt: fields[5] as DateTime,
      sourceLanguage: fields[6] as String?,
      translatedLanguages: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VideoItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.thumbnailPath)
      ..writeByte(4)
      ..write(obj.durationMs)
      ..writeByte(5)
      ..write(obj.importedAt)
      ..writeByte(6)
      ..write(obj.sourceLanguage)
      ..writeByte(7)
      ..write(obj.translatedLanguages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
