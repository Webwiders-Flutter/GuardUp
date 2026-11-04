/// Semantic type of content sent in a chat message.
enum MessageType {
  text,
  image,
  file,
  location,
  audio;

  bool get isText => this == MessageType.text;
  bool get isImage => this == MessageType.image;
  bool get isFile => this == MessageType.file;
}

