import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/engine_bloc.dart';
import 'bloc/game_bloc.dart';
import 'bloc/analysis_bloc.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const GrandmasterMentorApp());
}

class GrandmasterMentorApp extends StatelessWidget {
  const GrandmasterMentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => EngineBloc()),
        BlocProvider(create: (_) => GameBloc()),
        BlocProvider(create: (_) => AnalysisBloc()),
      ],
      child: MaterialApp(
        title: 'Cờ Tướng AI',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: _buildLightTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor:
          const Color(0xFFF5F5DC), // Beige/Cream background
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8B4513), // Saddle Brown
        secondary: Color(0xFFCC3333), // Red pieces
        surface: Color(0xFFFFF8DC), // Cornsilk panels
        onSurface: Color(0xFF2F4F4F), // Dark Slate Gray text
        error: Color(0xFFFF4444),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF8B4513),
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      tabBarTheme: ThemeData.light().tabBarTheme.copyWith(
            labelColor: const Color(0xFF8B4513),
            unselectedLabelColor: const Color(0xFF6B6B8A),
            indicatorSize: TabBarIndicatorSize.label,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Color(0xFF8B4513), width: 3),
            ),
          ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF2F4F4F)),
        bodySmall: TextStyle(color: Color(0xFF556B2F)),
      ),
    );
  }
}
