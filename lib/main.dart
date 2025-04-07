import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/todo_provider.dart';
import 'providers/monthly_goal_provider.dart';
import 'screens/home_screen.dart';
import 'screens/monthly_goal_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);
  
  // 앱 방향 설정 (세로 모드만 지원)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 화면 업데이트 속도 최적화
  // 성능 개선: 화면 업데이트 사이클 최적화
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()..init()),
        ChangeNotifierProvider(create: (_) => MonthlyGoalProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Momentum',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'NotoSansKR',
        ),
        home: const HomeScreen(),
        routes: {
          '/monthly-goal': (context) => const MonthlyGoalScreen(),
        },
        debugShowCheckedModeBanner: false,
        // 한글 지원을 위한 로컬라이제이션 설정
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('ko', 'KR'),
      ),
    );
  }
}