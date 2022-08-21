import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'base_model.dart';
import 'podcast_history_model.dart';

class PodcastModel extends BaseModel {
  @override
  final int? id;
  final createdAt;
  final String? url;
  final String? title;
  final String? subtitle;
  final String? imgPath;
  final String? author;
  final PodcastHistoryModel? podcastHistoryModel;

  PodcastModel({
    this.id,
    this.createdAt,
    this.title,
    this.url,
    this.subtitle,
    this.imgPath,
    this.author,
    this.podcastHistoryModel,
  });

  PodcastModel copyWith({
    int? id,
    createdAt,
    String? url,
    String? title,
    String? subtitle,
    bool? isDarkMode,
    String? imgPath,
    String? author,
    PodcastHistoryModel? podcastHistoryModel,
  }) {
    return PodcastModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      url: url ?? this.url,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imgPath: imgPath ?? this.imgPath,
      author: author ?? this.author,
      podcastHistoryModel: podcastHistoryModel ?? this.podcastHistoryModel,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    if (id != null) {
      result.addAll({'id': id});
    }

    if (createdAt != null) {
      result.addAll({'created_at': createdAt});
    }

    result.addAll({
      'url': url,
      'title': title,
      'subtitle': subtitle,
      'img_path': imgPath,
      'author': author,
    });

    return result;
  }

  factory PodcastModel.fromMap(Map<String, dynamic> map) {
    return PodcastModel(
        id: map['id']?.toInt(),
        createdAt: map['created_at'],
        url: map['url'],
        title: map['title'],
        subtitle: map['avatar_path'],
        imgPath: map['img_path'],
        author: map['author'],
        podcastHistoryModel: map['podcast_history'] != null &&
                (map['podcast_history'] as List).isNotEmpty
            ? PodcastHistoryModel.fromMap(
                (map['podcast_history'] as List).first)
            : PodcastHistoryModel(
                userEmail: Supabase.instance.client.auth.currentUser?.email,
                podcastId: map['id']?.toInt(),
                listened: 0,
              ));
  }

  String toJson() => json.encode(toMap());

  factory PodcastModel.fromJson(String source) =>
      PodcastModel.fromMap(json.decode(source));

  @override
  String toString() => toMap().toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PodcastModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  MediaItem get toMediaItem => MediaItem(
        id: url!,
        album: author,
        title: title!,
        artist: author,
        artUri: Uri.parse(imgPath!),
      );
}
