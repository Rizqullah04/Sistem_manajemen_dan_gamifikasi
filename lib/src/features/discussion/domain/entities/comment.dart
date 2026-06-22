class CommentItem {
  const CommentItem({
    required this.id,
    required this.userId,
    required this.kegiatanId,
    required this.content,
    required this.createdAt,
    this.userName,
  });

  final String id;
  final String userId;
  final String kegiatanId;
  final String content;
  final DateTime createdAt;
  final String? userName;
}
