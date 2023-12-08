import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller1;
  late VideoPlayerController _controller2;

  VideoPlayerController _controller3 =
      VideoPlayerController.networkUrl(Uri.parse("uri"));

  String inputVideo1Path =
      "/storage/emulated/0/Download/VideoTrimmerAndMerger/input-video-1.mp4";
  String inputVideo2Path =
      "/storage/emulated/0/Download/VideoTrimmerAndMerger/input-video-2.mp4";
  @override
  void initState() {
    super.initState();
    _controller1 = VideoPlayerController.file(File(inputVideo1Path))
      ..initialize().then((_) {
        setState(() {});
      });
    _controller2 = VideoPlayerController.file(File(inputVideo2Path))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  makeOutputVideoController(String outputVideoPath) {
    _controller3 = VideoPlayerController.file(File(outputVideoPath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  bool isOutputVideoProcessing = false;
  startLoader(BuildContext context) {
    setState(() {
      isOutputVideoProcessing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Text("Input Video 1"),
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: VideoPlayer(_controller1),
                  ),
                ],
              ),
              const SizedBox(
                width: 10,
              ),
              Column(
                children: [
                  const Text("Input Video 2"),
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: VideoPlayer(_controller2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Output Video"),
              isOutputVideoProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SizedBox(
                      height: 100,
                      width: 100,
                      child: VideoPlayer(_controller3),
                    ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          startLoader(context);
          setState(() async {
            String outputVideoPath = await editVideos(
              inputVideo1Path,
              inputVideo2Path,
            );
            makeOutputVideoController(outputVideoPath);
            isOutputVideoProcessing = false;
          });
        },
        label: const Column(
          children: [
            Text("Trim and Merge"),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }
}

Future<String> editVideos(String videoPath1, String videoPath2) async {
  final FlutterFFmpeg flutterFFmpeg = FlutterFFmpeg();

  String trimmedVideo1Path =
      "/storage/emulated/0/Download/VideoTrimmerAndMerger/trimmed-input-video-1.mp4";
  await flutterFFmpeg.execute(
    '-i $videoPath1 -ss 3 -t 7 -vf "scale=1920x1080,fps=24,format=yuv420p" -c:a copy $trimmedVideo1Path',
  );

  String trimmedVideo2Path =
      "/storage/emulated/0/Download/VideoTrimmerAndMerger/trimmed-input-video-2.mp4";
  await flutterFFmpeg.execute(
    '-i $videoPath2 -ss 3 -t 7 -vf "scale=1920x1080,fps=24,format=yuv420p" -c:a copy $trimmedVideo2Path',
  );

  String outputVideoPath =
      "/storage/emulated/0/Download/VideoTrimmerAndMerger/output-video.mp4";
  await flutterFFmpeg.execute(
    '-vsync 2 -i $trimmedVideo1Path -i $trimmedVideo2Path -filter_complex \'[0:v]setpts=PTS-STARTPTS,scale=1920x1080,fps=24,format=yuv420p[video0];[1:v]setpts=PTS-STARTPTS,scale=1920x1080,fps=24,format=yuv420p[video1];[video0][0:a:0][video1][1:a:0]concat=n=2:v=1:a=1[out]\' -map \'[out]\' $outputVideoPath',
  );
  return outputVideoPath;
}
