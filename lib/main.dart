import 'package:drawgrim/OpenPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

import 'Ranking.dart';

AudioPlayer _audioPlayer = AudioPlayer();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    _audioPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  Future<void> _playBackgroundMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.5);
    await _audioPlayer.play(AssetSource("BackgroundMusic.mp3"));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.gaeguTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1E1E2F  )),
        useMaterial3: true,
      ),
      home: OpenPage()
      // home: Ranking(first: "FIRST", second: "SECOND", third: "THIRD",),

      // StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), builder:(context,snapshot){
      //   if(snapshot.hasData){
      //     return const ChatPage();
      //   }else{
      //     return const Loginpage();
      //   }
      // }),
    );
  }
}
