import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/env_config.dart';
import '../models/general_playlist_info_model.dart';
import '../models/podcast_history_model.dart';
import '../models/podcast_info_model.dart';

import '../repositories/supabase_data_repository.dart';

class PodcastProvider extends ChangeNotifier {
  final _podcastInfoTable = 'podcast_info';
  final _podcastHistoryTable = 'podcast_history';
  final _generalPlaylistTable = 'general_playlist';
  final _generalPlaylistInfoTable = 'general_playlist_info';
  final _authorTable = 'author';

  bool _isLoading = false;
  SupabaseDataRepository? _supabaseDataRepository;
  List<GeneralPlaylistInfoModel>? _generalPlaylistInfoModel;

  final _podcasts = <PodcastInfoModel>[];
  final _podcastHistory = <PodcastHistoryModel>[];

  bool get isLoading => _isLoading;
  List<PodcastInfoModel> get podcast => _podcasts;
  List<PodcastHistoryModel> get podcastHistory => _podcastHistory;
  List<GeneralPlaylistInfoModel>? get generalPlaylistInfoModel =>
      _generalPlaylistInfoModel;

  PodcastProvider({SupabaseDataRepository? supabaseDataRepository}) {
    if (supabaseDataRepository != null) {
      _supabaseDataRepository = supabaseDataRepository;
    } else {
      _supabaseDataRepository = SupabaseDataRepository();
    }
  }

  Future<List<PodcastInfoModel>> fetch(
    BuildContext context, {
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();
    await supabaseCallAPI(context, function: () async {
      final response = await _supabaseDataRepository?.readRow(
        table: _podcastInfoTable,
        selectOption: '''
  *, $_podcastHistoryTable (
    listened, podcast_id, user_email, created_at, id
  ), $_authorTable (
    *
  )
''',
        column: '$_podcastHistoryTable.user_email',
        value: email,
      );

      if (response != null && response.isNotEmpty) {
        _podcasts.clear();
        _podcasts.addAll(
            response.map((e) => PodcastInfoModel.fromJson(jsonDecode(e))));
      }
    });

    _isLoading = false;
    notifyListeners();
    return podcast;
  }

  Future<List<PodcastHistoryModel>> getHistory(
    BuildContext context, {
    required String email,
  }) async {
    await supabaseCallAPI(context, function: () async {
      final response = await _supabaseDataRepository?.readRow(
        table: _podcastHistoryTable,
        selectOption: '''
*, $_podcastInfoTable (
  id, created_at, url, title, subtitle, img_path, $_authorTable (
      *
    )
  )''',
        column: 'user_email',
        value: email,
        orderID: 'created_at',
        ascending: false,
      );

      if (response != null && response.isNotEmpty) {
        _podcastHistory.clear();
        _podcastHistory.addAll(
          response.map((e) => PodcastHistoryModel.fromMap(e)),
        );
      }
    });

    _isLoading = false;
    notifyListeners();
    return _podcastHistory;
  }

  void sortHistory() {
    _podcastHistory.sort((a, b) =>
        DateTime.parse(b.createdAt!).compareTo(DateTime.parse(a.createdAt!)));

    notifyListeners();
  }

  Future<bool> updateHistory(
    BuildContext context, {
    required PodcastHistoryModel? historyDetail,
  }) async {
    var _isSuccess = false;
    await supabaseCallAPI(context, function: () async {
      if (historyDetail?.id == null) {
        await _supabaseDataRepository?.createRow(
          data: historyDetail!,
          table: _podcastHistoryTable,
        );
      } else {
        await _supabaseDataRepository?.updateRow(
          table: _podcastHistoryTable,
          keyName: 'podcast_id',
          keyValue: historyDetail!.podcastId,
          keyName2: 'user_email',
          keyValue2: historyDetail.userEmail,
          values: historyDetail.toMap(),
        );
      }
      _isSuccess = true;
    });
    return _isSuccess;
  }

  Future<List<PodcastInfoModel>> search(
    BuildContext context, {
    required String column,
    required List<String> searchingText,
  }) async {
    // final _filterdPodcast = <PodcastModel>[];
    // await supabaseCallAPI(context, function: () async {
    //   final response = await _supabaseDataRepository?.searchRow(
    //     table: _podcastInfoTable,
    //     column: column,
    //     value: searchingText,
    //   );
    //   if (response != null && response.isNotEmpty) {
    //     _filterdPodcast.addAll(response.map((e) => PodcastModel.fromMap(e)));
    //   }
    // });
    return _podcasts
        .where((element) =>
            element.title
                ?.toLowerCase()
                .contains(searchingText.first.toLowerCase()) ??
            false)
        .toList();
  }

  void updateHistoryLocal(
    BuildContext context, {
    PodcastHistoryModel? historyDetail,
  }) {
    if (historyDetail != null) {
      final removedIndex = _podcastHistory.indexWhere(
        (element) => element.podcastId == historyDetail.podcastId,
      );
      if (removedIndex != -1) {
        final removedItem = _podcastHistory.firstWhere(
          (element) => element.podcastId == historyDetail.podcastId,
        );
        _podcastHistory.removeWhere(
          (element) => element.podcastId == historyDetail.podcastId,
        );
        _podcastHistory.add(removedItem.copyWith(
          createdAt: historyDetail.createdAt,
          listened: historyDetail.listened,
        ));
      } else {
        _podcastHistory.add(PodcastHistoryModel(
          createdAt: historyDetail.createdAt,
          listened: historyDetail.listened,
          podcastId: historyDetail.podcastId,
        ));
      }

      sortHistory();
    }
  }

  Future<List<GeneralPlaylistInfoModel>?> getPlaylists(
    BuildContext context, {
    String? playlist_id,
  }) async {
    await supabaseCallAPI(
      context,
      function: () async {
        final res = await Supabase.instance.client
            .from(_generalPlaylistInfoTable)
            .select(
              '''
*, $_generalPlaylistTable (
  *, $_podcastInfoTable (
    *, $_authorTable (
      *
    ), $_podcastHistoryTable (
      *
    )
  )
)
''',
            )
            .order(
              'podcast_id',
              ascending: false,
              foreignTable: _generalPlaylistTable,
            )
            .range(
              0,
              TargetBuild.supabaseCacheSize,
              foreignTable: _generalPlaylistTable,
            );

        if (res != null && res.isNotEmpty) {
          _generalPlaylistInfoModel = (res as List)
              .map(
                (e) => GeneralPlaylistInfoModel.fromJson(e),
              )
              .toList();
        }
        notifyListeners();
      },
    );

    return _generalPlaylistInfoModel;
  }
}
