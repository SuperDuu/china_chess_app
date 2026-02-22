import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/analysis_bloc.dart';
import '../../bloc/game_bloc.dart';
import 'blind_spot_tab.dart';
import 'opponent_intent_tab.dart';
import 'position_map_tab.dart';
import 'deep_calc_tab.dart';

/// The main analysis dashboard below the board.
/// Contains 4 tabs: Blind Spot, Opponent Intent, Position Map, Deep Calculation.
class AnalysisDashboard extends StatelessWidget {
  const AnalysisDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8DC),
              border: Border(
                top: BorderSide(color: Color(0xFF8B4513), width: 1),
              ),
            ),
            child: const TabBar(
              labelColor: Color(0xFF8B4513),
              unselectedLabelColor: Color(0xFF6B6B8A),
              indicatorColor: Color(0xFF8B4513),
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
              tabs: [
                Tab(
                  icon: Icon(Icons.warning_amber_rounded, size: 16),
                  text: 'Điểm Mù',
                ),
                Tab(
                  icon: Icon(Icons.track_changes_rounded, size: 16),
                  text: 'Ý Đồ Địch',
                ),
                Tab(
                  icon: Icon(Icons.balance_rounded, size: 16),
                  text: 'Vị Thế',
                ),
                Tab(
                  icon: Icon(Icons.auto_awesome, size: 16),
                  text: 'Nhìn Xa',
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5DC),
              child: BlocBuilder<AnalysisBloc, AnalysisState>(
                builder: (ctx, state) => TabBarView(
                  children: [
                    BlindSpotTab(state: state),
                    OpponentIntentTab(state: state),
                    PositionMapTab(state: state),
                    DeepCalcTab(
                      state: state,
                      onPreviewMove: (move) =>
                          ctx.read<GameBloc>().add(PreviewMoveEvent(move)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
