// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:guardup/core/constants/env_config.dart';
// import 'package:guardup/core/utils/app_logs.dart';
// import 'package:guardup/core/utils/video_utils.dart';
// import 'package:supabase_flutter/supabase_flutter.dart' hide Headers;
// import 'package:wakelock_plus/wakelock_plus.dart';

// /// Infrastructure layer service to handle background isolates and foreground notifications
// @pragma('vm:entry-point')
// class BackgroundUploadService {
//   static const String notificationChannelId = 'upload_channel';
//   static const int notificationId = 888;
//   static bool _isInitialized = false;

//   static Future<void> initializeService() async {
//     if (_isInitialized) return;
//     final service = FlutterBackgroundService();

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       BackgroundUploadService.notificationChannelId,
//       'Video Upload Service',
//       description: 'This channel is used for video upload notifications.',
//       importance: Importance.low,
//     );

//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(channel);

//     const AndroidNotificationChannel completeChannel =
//         AndroidNotificationChannel(
//           'upload_complete_channel',
//           'Upload Alerts',
//           description: 'Notifications for completed or failed uploads.',
//           importance: Importance.high,
//         );

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(completeChannel);

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         autoStart: false,
//         isForegroundMode: true,
//         notificationChannelId: BackgroundUploadService.notificationChannelId,
//         initialNotificationTitle: 'Upload Service',
//         initialNotificationContent: 'Preparing upload',
//         foregroundServiceNotificationId: BackgroundUploadService.notificationId,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: false,
//         onForeground: onStart,
//         onBackground: onIosBackground,
//       ),
//     );
//     _isInitialized = true;
//   }

//   static Future<void> startUpload(Map<String, dynamic> uploadData) async {
//     AppLogs.info(
//       '[BackgroundUploadService] startUpload called for file: ${uploadData['filePath']}',
//     );
//     await initializeService();
//     final service = FlutterBackgroundService();
//     var isRunning = await service.isRunning();
//     AppLogs.info(
//       '[BackgroundUploadService] Background service isRunning: $isRunning',
//     );
//     if (!isRunning) {
//       final completer = Completer<void>();
//       StreamSubscription? sub;
//       bool isReady = false;
//       sub = service.on('serviceReady').listen((_) {
//         AppLogs.info(
//           '[BackgroundUploadService] serviceReady event received from isolate.',
//         );
//         isReady = true;
//         if (!completer.isCompleted) completer.complete();
//       });

//       AppLogs.info(
//         '[BackgroundUploadService] Calling service.startService()...',
//       );
//       await service.startService();

//       // Wait up to 8 seconds for the background isolate to initialize
//       await Future.any([
//         completer.future,
//         Future.delayed(const Duration(seconds: 8), () {
//           AppLogs.warning(
//             '[BackgroundUploadService] Timed out waiting 8s for serviceReady.',
//           );
//         }),
//       ]);
//       sub.cancel();

//       if (!isReady) {
//         throw Exception(
//           'Background upload service failed to start or initialize within 8 seconds.',
//         );
//       }
//     }

//     AppLogs.info(
//       '[BackgroundUploadService] Invoking "startUpload" event to service with fileName: ${uploadData['fileName']}',
//     );
//     service.invoke('startUpload', uploadData);
//   }

//   static void cancelUpload() {
//     AppLogs.warning('[BackgroundUploadService] cancelUpload called.');
//     FlutterBackgroundService().invoke('cancelUpload');
//   }
// }

// @pragma('vm:entry-point')
// void notificationTapBackground(NotificationResponse notificationResponse) {
//   DartPluginRegistrant.ensureInitialized();
//   WidgetsFlutterBinding.ensureInitialized();
//   if (notificationResponse.actionId == 'cancel_upload') {
//     FlutterBackgroundService().invoke('cancelUpload');
//   }
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   return true;
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   AppLogs.info(
//     '[BackgroundUploadService] onStart entrypoint triggered on ${Platform.operatingSystem}',
//   );
//   DartPluginRegistrant.ensureInitialized();
//   WidgetsFlutterBinding.ensureInitialized();

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   try {
//     await flutterLocalNotificationsPlugin.initialize(
//       const InitializationSettings(
//         android: AndroidInitializationSettings('@drawable/ic_notification'),
//         iOS: DarwinInitializationSettings(),
//       ),
//       onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
//     );
//     AppLogs.info(
//       '[BackgroundUploadService] Notifications plugin initialized in onStart',
//     );
//   } catch (e, st) {
//     AppLogs.error(
//       '[BackgroundUploadService] Failed to initialize notifications plugin in onStart',
//       error: e,
//       stackTrace: st,
//     );
//   }

//   // Initialize dependencies in isolate
//   try {
//     AppLogs.info(
//       '[BackgroundUploadService] Initializing EnvConfig & Supabase in isolate...',
//     );
//     await EnvConfig.init();
//     await Supabase.initialize(
//       url: EnvConfig.supabaseUrl,
//       anonKey: EnvConfig.supabaseAnonKey,
//     );
//     AppLogs.info(
//       '[BackgroundUploadService] Supabase successfully initialized in isolate.',
//     );
//   } catch (e, st) {
//     AppLogs.error(
//       '[BackgroundUploadService] Error initializing Supabase in isolate',
//       error: e,
//       stackTrace: st,
//     );
//   }

//   int currentProgress = 0;
//   bool isUploading = false;

//   service.on('stopService').listen((event) {
//     AppLogs.info('[BackgroundUploadService] Received stopService event.');
//     service.stopSelf();
//   });

//   service.on('requestStatus').listen((_) {
//     AppLogs.info(
//       '[BackgroundUploadService] Received requestStatus. isUploading: $isUploading, currentProgress: $currentProgress%',
//     );
//     if (isUploading) {
//       service.invoke('uploadProgress', {'progress': currentProgress});
//     }
//   });

//   service.on('startUpload').listen((event) async {
//     isUploading = true;
//     currentProgress = 0;
//     if (event == null) {
//       AppLogs.error(
//         '[BackgroundUploadService] startUpload received null event!',
//       );
//       return;
//     }
//     AppLogs.info(
//       '[BackgroundUploadService] startUpload event received. Event keys: ${event.keys.toList()}',
//     );

//     final String filePath = event['filePath'];
//     final String fileName = event['fileName'];
//     final String mimeType = event['mimeType'];

//     // DB fields
//     final String userId = event['userId'];
//     final String? thumbnailUrl = event['thumbnailUrl'];
//     final String title = event['title'];
//     final String description = event['description'];
//     final bool isAllCountries = event['isAllCountries'] ?? true;
//     final List<dynamic>? locations = event['locations'];
//     final List<dynamic>? countryCodes = event['countryCodes'];
//     final List<dynamic>? countryIds = event['countryIds'];
//     final String? languageCode = event['languageCode'];
//     final String? purposeId = event['purposeId'];
//     final String? categoryId = event['categoryId'];
//     final String? resolution = event['resolution'];
//     final int? fileSize = event['fileSize'];
//     final int? duration = event['duration'];
//     final int? bitrate = event['bitrate'];
//     final List<dynamic>? interests = event['interests'];

//     final bool isArabic = languageCode == 'ar';

//     try {
//       flutterLocalNotificationsPlugin.show(
//         BackgroundUploadService.notificationId,
//         isArabic ? 'جاري رفع الفيديو...' : 'Uploading Video',
//         isArabic ? 'جاري التجهيز...' : 'Starting upload...',
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             BackgroundUploadService.notificationChannelId,
//             isArabic ? 'خدمة رفع الفيديو' : 'Video Upload Service',
//             icon: '@drawable/ic_notification',
//             ongoing: true,
//             onlyAlertOnce: true,
//             showProgress: true,
//             maxProgress: 100,
//             progress: 0,
//             actions: <AndroidNotificationAction>[
//               AndroidNotificationAction(
//                 'cancel_upload',
//                 isArabic ? 'إلغاء' : 'Cancel',
//                 showsUserInterface: false,
//                 cancelNotification: true,
//               ),
//             ],
//           ),
//           iOS: const DarwinNotificationDetails(
//             presentAlert: false,
//             presentBadge: false,
//             presentSound: false,
//           ),
//         ),
//       );
//     } catch (e) {
//       AppLogs.warning(
//         '[BackgroundUploadService] Initial notification failed to show: $e',
//       );
//     }

//     try {
//       await WakelockPlus.enable();
//       final file = File(filePath);
//       final exists = await file.exists();
//       if (!exists) {
//         throw Exception('Video file does not exist at path: $filePath');
//       }
//       final fileLength = await file.length();
//       AppLogs.info(
//         '[BackgroundUploadService] File checked. Size: $fileLength bytes (${(fileLength / (1024 * 1024)).toStringAsFixed(2)} MB), mime: $mimeType',
//       );

//       int chunkSize;
//       if (fileLength > 100 * 1024 * 1024) {
//         chunkSize = 20 * 1024 * 1024; // 20MB
//       } else if (fileLength > 50 * 1024 * 1024) {
//         chunkSize = 10 * 1024 * 1024; // 10MB
//       } else {
//         chunkSize = 5 * 1024 * 1024; // 5MB
//       }
//       AppLogs.info(
//         '[BackgroundUploadService] Chunk size selected: ${(chunkSize / (1024 * 1024)).toStringAsFixed(0)} MB',
//       );

//       AppLogs.info(
//         '[BackgroundUploadService] Invoking Edge Function "multipart-r2-upload" (action: init)...',
//       );
//       final initResponse = await Supabase.instance.client.functions.invoke(
//         'multipart-r2-upload',
//         body: {
//           'action': 'init',
//           'video_name': fileName,
//           'content_type': mimeType,
//         },
//       );

//       AppLogs.info(
//         '[BackgroundUploadService] initResponse status: ${initResponse.status}, data: ${initResponse.data}',
//       );

//       if (initResponse.status != 200) {
//         throw Exception(
//           'Init failed: status ${initResponse.status}, data: ${initResponse.data}',
//         );
//       }

//       final uploadId = initResponse.data?['uploadId'];
//       final r2Key = initResponse.data?['key'];
//       if (uploadId == null || r2Key == null) {
//         throw Exception(
//           'Init response missing uploadId or key. Data: ${initResponse.data}',
//         );
//       }
//       AppLogs.info(
//         '[BackgroundUploadService] Upload initialized: uploadId: $uploadId, key: $r2Key',
//       );

//       final dio = Dio();
//       List<Map<String, dynamic>> parts = [];
//       int uploadedBytes = 0;
//       Map<int, int> inFlightBytes = {};

//       bool isCancelled = false;
//       final cancelToken = CancelToken();
//       service.on('cancelUpload').listen((_) {
//         AppLogs.warning(
//           '[BackgroundUploadService] cancelUpload received in isolate.',
//         );
//         isCancelled = true;
//         cancelToken.cancel();
//         flutterLocalNotificationsPlugin.cancel(
//           BackgroundUploadService.notificationId,
//         );
//       });

//       List<Map<String, dynamic>> chunks = [];
//       int pNum = 1;
//       for (int start = 0; start < fileLength; start += chunkSize) {
//         int end = start + chunkSize;
//         if (end > fileLength) end = fileLength;
//         chunks.add({'partNumber': pNum, 'start': start, 'length': end - start});
//         pNum++;
//       }
//       AppLogs.info(
//         '[BackgroundUploadService] Total chunks generated: ${chunks.length}',
//       );

//       const maxConcurrent = 3; // Upload 3 chunks at the same time

//       for (int i = 0; i < chunks.length; i += maxConcurrent) {
//         if (isCancelled) {
//           AppLogs.warning(
//             '[BackgroundUploadService] Upload cancelled before batch. Aborting...',
//           );
//           await Supabase.instance.client.functions.invoke(
//             'multipart-r2-upload',
//             body: {'action': 'abort', 'upload_id': uploadId, 'key': r2Key},
//           );
//           await VideoUtils.cleanUpCache();
//           service.invoke('uploadError', {'error': 'Upload Cancelled'});
//           service.stopSelf();
//           return;
//         }

//         final batch = chunks.skip(i).take(maxConcurrent).toList();
//         AppLogs.info(
//           '[BackgroundUploadService] Starting upload batch ${i ~/ maxConcurrent + 1}: parts ${batch.map((c) => c['partNumber']).toList()}',
//         );

//         final batchFutures = batch.map((chunk) async {
//           final int start = chunk['start'];
//           final int chunkLength = chunk['length'];
//           final int partNumber = chunk['partNumber'];

//           AppLogs.info(
//             '[BackgroundUploadService] [Part $partNumber] Requesting presigned URL...',
//           );
//           final urlResponse = await Supabase.instance.client.functions.invoke(
//             'multipart-r2-upload',
//             body: {
//               'action': 'get_url',
//               'upload_id': uploadId,
//               'key': r2Key,
//               'part_number': partNumber,
//             },
//           );

//           AppLogs.info(
//             '[BackgroundUploadService] [Part $partNumber] get_url response status: ${urlResponse.status}',
//           );

//           final preSignedUrl = urlResponse.data?['url'];
//           if (preSignedUrl == null) {
//             AppLogs.error(
//               '[BackgroundUploadService] [Part $partNumber] Presigned URL is null! Data: ${urlResponse.data}',
//             );
//             throw Exception('Failed to get presigned URL for part $partNumber');
//           }

//           String? eTag;
//           int retries = 0;

//           while (retries < 60) {
//             try {
//               if (isCancelled) break;
//               AppLogs.info(
//                 '[BackgroundUploadService] [Part $partNumber] Reading file slice: $start to ${start + chunkLength} ($chunkLength bytes)...',
//               );
//               final RandomAccessFile raf = await File(filePath).open();
//               raf.setPositionSync(start);
//               final Uint8List chunkBytes = raf.readSync(chunkLength);
//               raf.closeSync();

//               AppLogs.info(
//                 '[BackgroundUploadService] [Part $partNumber] Sending PUT to Cloudflare R2 (attempt ${retries + 1}/60)...',
//               );

//               final uploadResponse = await dio.put(
//                 preSignedUrl,
//                 data: chunkBytes,
//                 cancelToken: cancelToken,
//                 onSendProgress: (count, total) {
//                   inFlightBytes[partNumber] = count;
//                   int totalInFlight = inFlightBytes.values.fold(
//                     0,
//                     (a, b) => a + b,
//                   );
//                   int rawProgress =
//                       ((uploadedBytes + totalInFlight) / fileLength * 100)
//                           .toInt();
//                   int newProgress = (5.0 + (rawProgress * 0.95)).toInt();
//                   if (newProgress > currentProgress && newProgress <= 100) {
//                     currentProgress = newProgress;
//                     AppLogs.info(
//                       '[BackgroundUploadService] Progress update: $currentProgress% (part $partNumber: $count/$total bytes)',
//                     );
//                     service.invoke('uploadProgress', {
//                       'progress': currentProgress,
//                     });

//                     // Throttle notification updates (e.g., every 5% or so)
//                     if (currentProgress % 5 == 0) {
//                       try {
//                         flutterLocalNotificationsPlugin.show(
//                           BackgroundUploadService.notificationId,
//                           isArabic ? 'جاري رفع الفيديو...' : 'Uploading Video',
//                           isArabic
//                               ? 'التقدم: $currentProgress%'
//                               : 'Progress: $currentProgress%',
//                           NotificationDetails(
//                             android: AndroidNotificationDetails(
//                               BackgroundUploadService.notificationChannelId,
//                               isArabic
//                                   ? 'خدمة رفع الفيديو'
//                                   : 'Video Upload Service',
//                               icon: '@drawable/ic_notification',
//                               ongoing: true,
//                               onlyAlertOnce: true,
//                               showProgress: true,
//                               maxProgress: 100,
//                               progress: currentProgress,
//                               actions: <AndroidNotificationAction>[
//                                 AndroidNotificationAction(
//                                   'cancel_upload',
//                                   isArabic ? 'إلغاء' : 'Cancel',
//                                   showsUserInterface: false,
//                                   cancelNotification: true,
//                                 ),
//                               ],
//                             ),
//                             iOS: const DarwinNotificationDetails(
//                               presentAlert: false,
//                               presentBadge: false,
//                               presentSound: false,
//                             ),
//                           ),
//                         );
//                       } catch (_) {}
//                     }
//                   }
//                 },
//                 options: Options(
//                   headers: {
//                     'Content-Type': mimeType,
//                     Headers.contentLengthHeader: chunkLength.toString(),
//                   },
//                   sendTimeout: const Duration(minutes: 5),
//                 ),
//               );

//               eTag =
//                   uploadResponse.headers.value('etag') ??
//                   uploadResponse.headers.value('Etag') ??
//                   uploadResponse.headers.value('ETag');
//               AppLogs.info(
//                 '[BackgroundUploadService] [Part $partNumber] Response: status=${uploadResponse.statusCode}, eTag=$eTag',
//               );
//               if (eTag != null) {
//                 eTag = eTag.replaceAll('"', '');
//                 AppLogs.success(
//                   '[BackgroundUploadService] [Part $partNumber] Upload succeeded! ETag: $eTag',
//                 );
//                 break;
//               } else {
//                 AppLogs.warning(
//                   '[BackgroundUploadService] [Part $partNumber] ETag header missing from PUT response! Status: ${uploadResponse.statusCode}, headers: ${uploadResponse.headers.map}',
//                 );
//               }
//             } catch (e, st) {
//               if (cancelToken.isCancelled) {
//                 AppLogs.warning(
//                   '[BackgroundUploadService] [Part $partNumber] Upload cancelled via CancelToken.',
//                 );
//                 break;
//               }
//               AppLogs.error(
//                 '[BackgroundUploadService] [Part $partNumber] Upload attempt ${retries + 1}/60 failed: $e',
//                 error: e,
//                 stackTrace: st,
//               );
//               if (e is DioException) {
//                 AppLogs.error(
//                   '[BackgroundUploadService] [Part $partNumber] DioException details: '
//                   'type=${e.type}, message=${e.message}, '
//                   'statusCode=${e.response?.statusCode}, '
//                   'statusMessage=${e.response?.statusMessage}, '
//                   'responseData=${e.response?.data}, '
//                   'responseHeaders=${e.response?.headers.map}',
//                 );
//               }
//               retries++;
//               AppLogs.info(
//                 '[BackgroundUploadService] [Part $partNumber] Sleeping 10s before retry...',
//               );
//               await Future.delayed(const Duration(seconds: 10));
//             }
//           }

//           if (isCancelled) return null;
//           if (eTag == null) {
//             throw Exception(
//               'Upload failed: Part $partNumber could not complete after 60 retries.',
//             );
//           }

//           return {
//             'part': {'partNumber': partNumber, 'eTag': eTag},
//             'bytes': chunkLength,
//           };
//         }).toList();

//         final results = await Future.wait(batchFutures);

//         for (var res in results) {
//           if (res == null) break;
//           final part = res['part'] as Map<String, dynamic>;
//           parts.add(part);
//           uploadedBytes += res['bytes'] as int;
//           inFlightBytes.remove(part['partNumber']);
//         }

//         if (isCancelled) break;
//       }

//       if (isCancelled) {
//         try {
//           await Supabase.instance.client.functions.invoke(
//             'multipart-r2-upload',
//             body: {'action': 'abort', 'upload_id': uploadId, 'key': r2Key},
//           );
//         } catch (_) {}
//         await VideoUtils.cleanUpCache();
//         service.invoke('uploadError', {'error': 'Upload Cancelled'});

//         try {
//           await flutterLocalNotificationsPlugin.show(
//             BackgroundUploadService.notificationId + 1,
//             isArabic ? 'تم إلغاء الرفع' : 'Upload Cancelled',
//             isArabic
//                 ? 'تم إلغاء رفع الفيديو.'
//                 : 'The video upload was cancelled.',
//             const NotificationDetails(
//               android: AndroidNotificationDetails(
//                 'upload_complete_channel',
//                 'Upload Alerts',
//                 icon: '@drawable/ic_notification',
//                 importance: Importance.high,
//                 priority: Priority.high,
//               ),
//               iOS: DarwinNotificationDetails(
//                 presentAlert: true,
//                 presentBadge: true,
//                 presentSound: true,
//               ),
//             ),
//             payload: jsonEncode({'screenName': 'uploadVideo'}),
//           );
//         } catch (_) {}

//         service.stopSelf();
//         return;
//       }

//       // Complete Multipart Upload
//       AppLogs.info(
//         '[BackgroundUploadService] All parts uploaded (${parts.length} parts). Calling complete on Edge Function...',
//       );
//       final completeResponse = await Supabase.instance.client.functions.invoke(
//         'multipart-r2-upload',
//         body: {
//           'action': 'complete',
//           'upload_id': uploadId,
//           'key': r2Key,
//           'parts': parts,
//         },
//       );
//       AppLogs.info(
//         '[BackgroundUploadService] completeResponse status: ${completeResponse.status}, data: ${completeResponse.data}',
//       );
//       if (completeResponse.status != 200) {
//         throw Exception(
//           'Complete multipart upload failed: status ${completeResponse.status}, data: ${completeResponse.data}',
//         );
//       }

//       // Insert into DB
//       AppLogs.info(
//         '[BackgroundUploadService] Inserting video into Supabase DB...',
//       );
//       final insertData = {
//         'user_id': userId,
//         'video_url': r2Key,
//         'thumbnail_url': thumbnailUrl,
//         'title': title,
//         'description': description,
//         'is_all_countries': isAllCountries,
//         'status': 'processing',
//         'created_at': DateTime.now().toUtc().toIso8601String(),
//       };

//       if (locations != null) insertData['locations'] = locations;
//       if (countryCodes != null) insertData['country_codes'] = countryCodes;
//       if (countryIds != null) insertData['country_ids'] = countryIds;
//       if (languageCode != null) insertData['language_code'] = languageCode;
//       if (purposeId != null) insertData['purpose_id'] = purposeId;
//       if (categoryId != null) insertData['category_id'] = categoryId;
//       if (resolution != null) insertData['resolution'] = resolution;
//       if (interests != null) insertData['interests'] = interests;
//       if (fileSize != null) insertData['file_size'] = fileSize;
//       if (duration != null) insertData['duration'] = duration;
//       if (bitrate != null) insertData['bitrate'] = bitrate;

//       final response = await Supabase.instance.client
//           .from('videos')
//           .insert(insertData)
//           .select('id')
//           .single();

//       AppLogs.success(
//         '[BackgroundUploadService] Video record inserted! Emitting uploadComplete for videoId: ${response['id']}',
//       );

//       service.invoke('uploadComplete', {
//         'videoId': response['id'],
//         'url': r2Key,
//       });

//       try {
//         await flutterLocalNotificationsPlugin.show(
//           BackgroundUploadService.notificationId + 2,
//           isArabic ? 'تم الرفع' : 'Upload Complete',
//           isArabic ? 'تم رفع الفيديو بنجاح!' : 'Video uploaded successfully',
//           const NotificationDetails(
//             android: AndroidNotificationDetails(
//               'upload_complete_channel',
//               'Upload Alerts',
//               icon: '@drawable/ic_notification',
//               importance: Importance.high,
//               priority: Priority.high,
//             ),
//             iOS: DarwinNotificationDetails(
//               presentAlert: true,
//               presentBadge: true,
//               presentSound: true,
//             ),
//           ),
//           payload: jsonEncode({
//             'type': 'new_video',
//             'video_id': response['id'],
//           }),
//         );
//       } catch (_) {}

//       await VideoUtils.cleanUpCache();
//       await Future.delayed(const Duration(seconds: 2));
//       isUploading = false;
//       service.stopSelf();
//     } catch (e, stackTrace) {
//       isUploading = false;
//       AppLogs.error(
//         '[BackgroundUploadService] ❌ CRITICAL: Upload failed: $e',
//         error: e,
//         stackTrace: stackTrace,
//       );
//       await VideoUtils.cleanUpCache();
//       service.invoke('uploadError', {'error': e.toString()});
//       try {
//         await flutterLocalNotificationsPlugin.show(
//           BackgroundUploadService.notificationId + 3,
//           isArabic ? 'فشل الرفع' : 'Upload Failed',
//           isArabic
//               ? 'فشل في الرفع. يرجى المحاولة مرة أخرى.'
//               : 'Could not complete upload.',
//           const NotificationDetails(
//             android: AndroidNotificationDetails(
//               'upload_complete_channel',
//               'Upload Alerts',
//               icon: '@drawable/ic_notification',
//               importance: Importance.high,
//               priority: Priority.high,
//             ),
//             iOS: DarwinNotificationDetails(
//               presentAlert: true,
//               presentBadge: true,
//               presentSound: true,
//             ),
//           ),
//           payload: jsonEncode({'screenName': 'uploadVideo'}),
//         );
//       } catch (_) {}
//       service.stopSelf();
//     } finally {
//       try {
//         await WakelockPlus.disable();
//       } catch (_) {}
//     }
//   });

//   AppLogs.info('[BackgroundUploadService] Emitting serviceReady from isolate.');
//   service.invoke('serviceReady');
// }
