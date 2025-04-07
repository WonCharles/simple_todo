import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monthly_goal_model.dart';

class MonthlyGoalService {
  static const String _goalsKey = 'monthly_goals';

  // 모든 월간 목표 가져오기
  Future<List<MonthlyGoal>> getAllGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];
    
    return goalsJson
        .map((goalJson) => MonthlyGoal.fromJson(jsonDecode(goalJson)))
        .toList();
  }

  // 특정 월의 목표 목록 가져오기
  Future<List<MonthlyGoal>> getGoalsByMonth(int year, int month) async {
    final goals = await getAllGoals();
    return goals.where(
      (goal) => goal.year == year && goal.month == month,
    ).toList();
  }

  // 현재 월의 목표 목록 가져오기
  Future<List<MonthlyGoal>> getCurrentMonthGoals() async {
    final now = DateTime.now();
    return getGoalsByMonth(now.year, now.month);
  }

  // 월간 목표 추가
  Future<void> addGoal(MonthlyGoal goal) async {
    final goals = await getAllGoals();
    goals.add(goal);
    await _saveGoals(goals);
  }

  // 월간 목표 업데이트
  Future<void> updateGoal(MonthlyGoal updatedGoal) async {
    final goals = await getAllGoals();
    final index = goals.indexWhere((goal) => goal.id == updatedGoal.id);
    
    if (index != -1) {
      goals[index] = updatedGoal;
      await _saveGoals(goals);
    }
  }

  // 월간 목표 완료 상태 변경
  Future<void> toggleGoalCompletion(String id) async {
    final goals = await getAllGoals();
    final index = goals.indexWhere((goal) => goal.id == id);
    
    if (index != -1) {
      goals[index] = goals[index].copyWith(isCompleted: !goals[index].isCompleted);
      await _saveGoals(goals);
    }
  }

  // 월간 목표 삭제
  Future<void> deleteGoal(String id) async {
    final goals = await getAllGoals();
    goals.removeWhere((goal) => goal.id == id);
    await _saveGoals(goals);
  }

  // 모든 월간 목표 저장
  Future<void> _saveGoals(List<MonthlyGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = goals.map((goal) => jsonEncode(goal.toJson())).toList();
    await prefs.setStringList(_goalsKey, goalsJson);
  }
}