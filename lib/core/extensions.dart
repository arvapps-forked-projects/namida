import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Playlist;

import 'package:namida/class/playlist.dart';
import 'package:namida/class/track.dart';
import 'package:namida/controller/indexer_controller.dart';
import 'package:namida/controller/playlist_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/translations/strings.dart';
import 'package:namida/ui/pages/albums_page.dart';
import 'package:namida/ui/pages/artists_page.dart';
import 'package:namida/ui/pages/folders_page.dart';
import 'package:namida/ui/pages/genres_page.dart';
import 'package:namida/ui/pages/playlists_page.dart';
import 'package:namida/ui/pages/tracks_page.dart';

extension DurationLabel on Duration {
  String get label {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = "${twoDigits(inMinutes.remainder(60))}:";
    String twoDigitSeconds = twoDigits(inSeconds.remainder(60));
    String durinHour = inHours > 0 ? "${twoDigits(inHours)}:" : '';
    return "$durinHour$twoDigitMinutes$twoDigitSeconds";
  }
}

extension StringOverflow on String {
  String get overflow => this != '' ? characters.replaceAll(Characters(''), Characters('\u{200B}')).toString() : '';
}

extension PathFormat on String {
  String get formatPath => replaceFirst('/0', '').replaceFirst('/storage/', '').replaceFirst('emulated/', '');
}

extension AllDirInDir on String {
  List<String> get getDirectoriesInside {
    final allFolders = Indexer.inst.groupedFoldersMap;
    return allFolders.keys.where((key) => key.startsWith(this)).toList();
  }
}

extension UtilExtensions on String {
  List<String> multiSplit(Iterable<String> delimeters) => delimeters.isEmpty
      ? [this]
      : split(
          RegExp(delimeters.map(RegExp.escape).join('|')),
        );
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
        <K, List<E>>{},
        (Map<K, List<E>> map, E element) => map..putIfAbsent(keyFunction(element), () => <E>[]).add(element),
      );
}

extension TracksUtils on List<Track> {
  int get totalDuration {
    int totalFinalDuration = 0;

    for (var t in this) {
      totalFinalDuration += t.duration ~/ 1000;
    }
    return totalFinalDuration;
  }

  String get totalDurationFormatted {
    int totalDurationFinal = totalDuration;
    String formattedTotalTracksDuration =
        "${Duration(seconds: totalDurationFinal).inHours == 0 ? "" : "${Duration(seconds: totalDurationFinal).inHours} h "}${Duration(seconds: totalDurationFinal).inMinutes.remainder(60) == 0 ? "" : "${Duration(seconds: totalDurationFinal).inMinutes.remainder(60) + 1} min"}";
    return formattedTotalTracksDuration;
  }

  String get displayTrackKeyword {
    return '$length ${length == 1 ? Language.inst.TRACK : Language.inst.TRACKS}';
  }
}

extension DisplayKeywords on int {
  String get displayAlbumKeyword {
    return '$this ${this == 1 ? Language.inst.ALBUM : Language.inst.ALBUMS}';
  }

  String get displayArtistKeyword {
    return '$this ${this == 1 ? Language.inst.ARTIST : Language.inst.ARTISTS}';
  }

  String get displayGenreKeyword {
    return '$this ${this == 1 ? Language.inst.GENRE : Language.inst.GENRES}';
  }

  String get displayFolderKeyword {
    return '$this ${this == 1 ? Language.inst.FOLDER : Language.inst.FOLDERS}';
  }
}

extension PlaylistUtils on List<Playlist> {
  String get displayPlaylistKeyword {
    return '$length ${length == 1 ? Language.inst.PLAYLIST : Language.inst.PLAYLISTS}';
  }
}

///
extension ArtistAlbums on String {
  Map<String?, Set<Track>> get artistAlbums {
    return Indexer.inst.getAlbumsForArtist(this);
  }
}

extension YearDateFormatted on int {
  String get yearFormatted {
    if (this == 0) {
      return '';
    }
    final formatDate = DateFormat('${SettingsController.inst.dateTimeFormat}');
    final yearFormatted = toString().length == 8 ? formatDate.format(DateTime.parse(toString())) : toString();

    return yearFormatted;
  }

  String get dateFormatted {
    //TODO: Date Format
    final formatDate = DateFormat('dd MMM yyyy');
    final dateFormatted = formatDate.format(DateTime.fromMillisecondsSinceEpoch(this));

    return dateFormatted;
  }
}

extension BorderRadiusSetting on double {
  double get multipliedRadius {
    return this * SettingsController.inst.borderRadiusMultiplier.value;
  }
}

extension TrackItemSubstring on TrackTileItem {
  String get label => toString().substring(14);
}

extension EmptyString on String {
  String? get isValueEmpty {
    if (this == '') {
      return null;
    }
    return this;
  }
}

extension Channels on String {
  String? get channelToLabel {
    final ch = int.tryParse(this) ?? 3;
    if (ch == 0) {
      return '';
    }
    if (ch == 1) {
      return 'mono';
    }
    if (ch == 2) {
      return 'stereo';
    }
    return this;
  }
}

extension FavouriteTrack on Track {
  bool get isFavourite {
    final favPlaylist = PlaylistController.inst.playlistList.firstWhere(
      (element) => element.id == -1,
    );
    return favPlaylist.tracks.contains(this);
  }
}

extension FileSizeFormat on int {
  String get fileSizeFormatted {
    const decimals = 2;
    if (this <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(this) / log(1024)).floor();
    return '${(this / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}

extension LibraryTabToInt on LibraryTab {
  int get toInt {
    // return SettingsController.inst.libraryTabs.toList().indexOf(toText);
    final libtabs = SettingsController.inst.libraryTabs.toList();
    if (this == LibraryTab.albums) {
      return libtabs.indexOf('albums');
    }
    if (this == LibraryTab.tracks) {
      return libtabs.indexOf('tracks');
    }
    if (this == LibraryTab.artists) {
      return libtabs.indexOf('artists');
    }
    if (this == LibraryTab.genres) {
      return libtabs.indexOf('genres');
    }
    if (this == LibraryTab.playlists) {
      return libtabs.indexOf('playlists');
    }
    if (this == LibraryTab.folders) {
      return libtabs.indexOf('folders');
    }
    return libtabs.indexOf('tracks');
  }
}

extension LibraryTabToEnum on int {
  LibraryTab get toEnum {
    final libtabs = SettingsController.inst.libraryTabs.toList();
    if (this == libtabs.indexOf('albums')) {
      return LibraryTab.albums;
    }
    if (this == libtabs.indexOf('tracks')) {
      return LibraryTab.tracks;
    }
    if (this == libtabs.indexOf('artists')) {
      return LibraryTab.artists;
    }
    if (this == libtabs.indexOf('genres')) {
      return LibraryTab.genres;
    }
    if (this == libtabs.indexOf('playlists')) {
      return LibraryTab.playlists;
    }
    if (this == libtabs.indexOf('folders')) {
      return LibraryTab.folders;
    }
    return LibraryTab.tracks;
  }
}

extension LibraryTabFromString on String {
  LibraryTab get toEnum {
    if (this == 'albums') {
      return LibraryTab.albums;
    }
    if (this == 'tracks') {
      return LibraryTab.tracks;
    }
    if (this == 'artists') {
      return LibraryTab.artists;
    }
    if (this == 'genres') {
      return LibraryTab.genres;
    }
    if (this == 'playlists') {
      return LibraryTab.playlists;
    }
    if (this == 'folders') {
      return LibraryTab.folders;
    }
    return LibraryTab.tracks;
  }
}

extension LibraryTabToWidget on LibraryTab {
  Widget get toWidget {
    if (this == LibraryTab.albums) {
      return AlbumsPage();
    }
    if (this == LibraryTab.tracks) {
      return TracksPage();
    }
    if (this == LibraryTab.artists) {
      return ArtistsPage();
    }
    if (this == LibraryTab.genres) {
      return GenresPage();
    }
    if (this == LibraryTab.playlists) {
      return PlaylistsPage();
    }
    if (this == LibraryTab.folders) {
      return FoldersPage();
    }
    return const SizedBox();
  }

  IconData get toIcon {
    if (this == LibraryTab.albums) {
      return Broken.music_dashboard;
    }
    if (this == LibraryTab.tracks) {
      return Broken.music_circle;
    }
    if (this == LibraryTab.artists) {
      return Broken.profile_2user;
    }
    if (this == LibraryTab.genres) {
      return Broken.smileys;
    }
    if (this == LibraryTab.playlists) {
      return Broken.music_library_2;
    }
    if (this == LibraryTab.folders) {
      return Broken.folder;
    }
    return Broken.music_circle;
  }

  String get toText {
    if (this == LibraryTab.albums) {
      return Language.inst.ALBUMS;
    }
    if (this == LibraryTab.tracks) {
      return Language.inst.TRACKS;
    }
    if (this == LibraryTab.artists) {
      return Language.inst.ARTISTS;
    }
    if (this == LibraryTab.genres) {
      return Language.inst.GENRES;
    }
    if (this == LibraryTab.playlists) {
      return Language.inst.PLAYLISTS;
    }
    if (this == LibraryTab.folders) {
      return Language.inst.FOLDERS;
    }
    return Language.inst.TRACKS;
  }
}

extension SortToText on SortType {
  String get toText {
    if (this == SortType.title) {
      return Language.inst.TITLE;
    }
    if (this == SortType.album) {
      return Language.inst.ALBUM;
    }
    if (this == SortType.albumArtist) {
      return Language.inst.ALBUM_ARTIST;
    }
    if (this == SortType.artistsList) {
      return Language.inst.ARTISTS;
    }
    if (this == SortType.bitrate) {
      return Language.inst.BITRATE;
    }
    if (this == SortType.composer) {
      return Language.inst.COMPOSER;
    }
    if (this == SortType.dateAdded) {
      return Language.inst.DATE_ADDED;
    }
    if (this == SortType.dateModified) {
      return Language.inst.DATE_MODIFIED;
    }
    if (this == SortType.discNo) {
      return Language.inst.DISC_NUMBER;
    }
    if (this == SortType.displayName) {
      return Language.inst.FILE_NAME;
    }
    if (this == SortType.duration) {
      return Language.inst.DURATION;
    }
    if (this == SortType.genresList) {
      return Language.inst.GENRES;
    }
    if (this == SortType.sampleRate) {
      return Language.inst.SAMPLE_RATE;
    }
    if (this == SortType.size) {
      return Language.inst.SIZE;
    }
    if (this == SortType.year) {
      return Language.inst.YEAR;
    }

    return '';
  }
}

extension GroupSortToText on GroupSortType {
  String get toText {
    if (this == GroupSortType.album) {
      return Language.inst.ALBUM;
    }
    if (this == GroupSortType.albumArtist) {
      return Language.inst.ALBUM_ARTIST;
    }
    if (this == GroupSortType.artistsList) {
      return Language.inst.ARTISTS;
    }
    if (this == GroupSortType.genresList) {
      return Language.inst.GENRES;
    }

    if (this == GroupSortType.composer) {
      return Language.inst.COMPOSER;
    }
    if (this == GroupSortType.dateModified) {
      return Language.inst.DATE_MODIFIED;
    }
    if (this == GroupSortType.duration) {
      return Language.inst.DURATION;
    }
    if (this == GroupSortType.numberOfTracks) {
      return Language.inst.NUMBER_OF_TRACKS;
    }
    if (this == GroupSortType.year) {
      return Language.inst.YEAR;
    }

    return '';
  }
}

extension YTVideoQuality on String {
  VideoQuality get toVideoQuality {
    if (this == '144p') {
      return VideoQuality.low144;
    }
    if (this == '240p') {
      return VideoQuality.low240;
    }
    if (this == '360p') {
      return VideoQuality.medium360;
    }
    if (this == '480p') {
      return VideoQuality.medium480;
    }
    if (this == '720p') {
      return VideoQuality.high720;
    }
    if (this == '1080p') {
      return VideoQuality.high1080;
    }
    if (this == '2k') {
      return VideoQuality.high1440;
    }
    if (this == '4k') {
      return VideoQuality.high2160;
    }
    if (this == '8k') {
      return VideoQuality.high4320;
    }
    return VideoQuality.low144;
  }
}