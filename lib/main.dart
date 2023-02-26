import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:namida/packages/miniplayer.dart';
import 'package:namida/controller/player_controller.dart';
import 'package:namida/controller/playlist_controller.dart';
import 'package:namida/controller/scroll_search_controller.dart';
import 'package:namida/controller/video_controller.dart';
import 'package:namida/controller/folders_controller.dart';
import 'package:namida/controller/queue_controller.dart';
import 'package:namida/core/translations/strings.dart';
import 'package:namida/ui/widgets/selected_tracks_preview.dart';
import 'package:namida/controller/indexer_controller.dart';
import 'package:namida/controller/current_color.dart';
import 'package:namida/controller/selected_tracks_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/themes.dart';
import 'package:namida/core/translations/translations.dart';
import 'package:namida/ui/pages/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Getting Device info
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  final sdkVersion = androidInfo.version.sdkInt;

  /// Granting Storage Permission
  if (await Permission.storage.status.isDenied || await Permission.storage.status.isPermanentlyDenied) {
    final st = await Permission.storage.request();
    if (!st.isGranted) {
      SystemNavigator.pop();
    }
  }
  if (sdkVersion >= 33 && (await Permission.audio.status.isDenied || await Permission.audio.status.isPermanentlyDenied)) {
    final st = await Permission.audio.request();
    if (!st.isGranted) {
      SystemNavigator.pop();
    }
  }

  // await Get.dialog(
  //   CustomBlurryDialog(
  //     title: Language.inst.STORAGE_PERMISSION,
  //     bodyText: Language.inst.STORAGE_PERMISSION_SUBTITLE,
  //     actions: [
  // CancelButton(),
  //       ElevatedButton(
  //         onPressed: () async {
  //           await Permission.storage.request();
  //           Get.close(1);
  //         },
  //         child: Text(Language.inst.GRANT_ACCESS),
  //       ),
  //     ],
  //   ),
  // );

  await GetStorage.init('NamidaSettings');

  kAppDirectoryPath = await getApplicationDocumentsDirectory().then((value) => value.path);
  await Directory(kArtworksDirPath).create();
  await Directory(kArtworksCompDirPath).create();
  await Directory(kWaveformDirPath).create();
  await Directory(kVideosCachePath).create();
  await Directory(kVideosCacheTempPath).create();

  final paths = await ExternalPath.getExternalStorageDirectories();
  kDirectoriesPaths = paths.map((path) => "$path/${ExternalPath.DIRECTORY_MUSIC}").toSet();
  kDirectoriesPaths.add('${paths[0]}/Download/');
  kInternalAppDirectoryPath = "${paths[0]}/Namida";

  Get.put(() => SettingsController());
  Get.put(() => SelectedTracksController());
  Get.put(() => ScrollSearchController());
  Get.put(() => Player());
  Get.put(() => VideoController());
  Get.put(() => Folders());
  await Player.inst.initializePlayer();

  final tfe = await File(kTracksFilePath).exists() && await File(kTracksFilePath).stat().then((value) => value.size > 80);
  if (tfe) {
    await Indexer.inst.prepareTracksFile(tfe);
  } else {
    Indexer.inst.prepareTracksFile(tfe);
  }
  await PlaylistController.inst.preparePlaylistFile();
  await QueueController.inst.prepareQueueFile();
  await VideoController.inst.getVideoFiles();

  runApp(const MyApp());
}

Future<bool> requestManageStoragePermission() async {
  // final shouldRequest = !await Permission.manageExternalStorage.isGranted || await Permission.manageExternalStorage.isDenied;
  if (!await Permission.manageExternalStorage.isGranted) {
    await Permission.manageExternalStorage.request();
  }

  if (!await Permission.manageExternalStorage.isGranted || await Permission.manageExternalStorage.isDenied) {
    Get.snackbar(Language.inst.STORAGE_PERMISSION_DENIED, Language.inst.STORAGE_PERMISSION_DENIED_SUBTITLE);
    return false;
  }
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Namida',
        theme: AppThemes.inst.getAppTheme(CurrentColor.inst.color.value, light: true),
        darkTheme: AppThemes.inst.getAppTheme(CurrentColor.inst.color.value, light: false),
        themeMode: SettingsController.inst.themeMode.value,
        translations: MyTranslation(),
        builder: (context, widget) {
          return ScrollConfiguration(behavior: const ScrollBehaviorModified(), child: widget!);
        },
        home: MediaQuery(
          data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(
            textScaleFactor: SettingsController.inst.fontScaleFactor.value,
          ),
          child: WillPopScope(
              onWillPop: () async {
                return Future.value(false);
              },
              child:

                  // return AnnotatedRegion<SystemUiOverlayStyle>(
                  //     value: SystemUiOverlayStyle(
                  //       // statusBarBrightness: Brightness.light,
                  //       // statusBarColor: Colors.grey.shade900,
                  //       // statusBarIconBrightness: Brightness.light,
                  //       systemNavigationBarColor: Colors.white.withAlpha(25),
                  //       systemNavigationBarDividerColor: Get.theme.bottomNavigationBarTheme.backgroundColor,
                  //       systemNavigationBarIconBrightness: Brightness.light,
                  //     ),
                  //     child:
                  Stack(
                children: [
                  HomePage(),
                  MiniPlayerParent(),
                  const Positioned(
                    bottom: 60.0,
                    child: SelectedTracksPreviewContainer(),
                  ),
                ],
              )
              // );

              ),
        ),
        // child: AnimatedTheme(duration: Duration(seconds: 5), data: AppThemes().getAppTheme(CurrentColor.inst.color.value, light: false), child: HomePage())),
        // initialRoute: '/',
        // getPages: [
        //   GetPage(name: '/', page: () => HomePage()),
        //   GetPage(name: '/trackspage', page: () => TracksPage()),
        // ],
      ),
    );
  }
}

class ScrollBehaviorModified extends ScrollBehavior {
  const ScrollBehaviorModified();
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
        return const BouncingScrollPhysics();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const ClampingScrollPhysics();
    }
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  _KeepAliveWrapperState createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Dismiss keyboard when a new screen is navigated to
    Get.focusScope?.unfocus();
    super.didPush(route, previousRoute);
  }
}