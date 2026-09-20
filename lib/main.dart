import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:minimal_mp3_player/player/player.dart';
import 'package:minimal_mp3_player/widgets/account.dart';
import 'package:minimal_mp3_player/widgets/home.dart';
import 'package:minimal_mp3_player/widgets/login.dart';
import 'package:minimal_mp3_player/widgets/splash.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  String supabaseUrl = dotenv.get('SUPABASE_URL');
  String supabaseAnonKey = dotenv.get('SUPABASE_API_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateStore()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        '/': (_) => const SplashPage(),
        '/home': (_) => const HomePage(),
        '/account': (_) => const AccountPage(),
        '/login': (_) => const LoginPage(),
      },
      initialRoute: '/home',
      theme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
        textTheme: ShadTextTheme(
          family: 'Geist',
        ),
      ),
    );
  }
}
