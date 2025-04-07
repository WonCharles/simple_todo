import 'package:flutter/foundation.dart';
import '../models/monthly_goal_model.dart';
import '../services/monthly_goal_service.dart';

class MonthlyGoalProvider with ChangeNotifier {
  final MonthlyGoalService _goalService = MonthlyGoalService();
  
  List<MonthlyGoal> _currentMonthGoals = [];
  List<MonthlyGoal> _monthlyGoals = [];
  bool _isLoading = false;

  // Getters
  List<MonthlyGoal> get currentMonthGoals => _currentMonthGoals;
  List<MonthlyGoal> get monthlyGoals => _monthlyGoals;
  bool get isLoading => _isLoading;

  // 초기화 함수
  Future<void> init() async {
    await fetchCurrentMonthGoals();
  }

  // 현재 월 목표 목록 가져오기
  Future<void> fetchCurrentMonthGoals() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentMonthGoals = await _goalService.getCurrentMonthGoals();
      _currentMonthGoals.sort((a, b) => a.isCompleted ? 1 : 0);
    } catch (e) {
      print('현재 월 목표를 가져오는 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 특정 월의 목표 목록 가져오기
  Future<void> fetchGoalsByMonth(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _monthlyGoals = await _goalService.getGoalsByMonth(year, month);
      // 완료된 목표가 리스트 뒤쪽으로 가도록 정렬
      _monthlyGoals.sort((a, b) => a.isCompleted ? 1 : 0);
    } catch (e) {
      print('특정 월의 목표를 가져오는 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 월간 목표 추가 (현재 월)
  Future<void> addGoal(String content) async {
    final now = DateTime.now();
    
    final MonthlyGoal goal = MonthlyGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      year: now.year,
      month: now.month,
    );
    
    try {
      await _goalService.addGoal(goal);
      await fetchCurrentMonthGoals();
    } catch (e) {
      print('월간 목표 추가 중 오류 발생: $e');
    }
  }
  
  // 특정 월에 목표 추가
  Future<void> addGoalForMonth(String content, int year, int month) async {
    final MonthlyGoal goal = MonthlyGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      year: year,
      month: month,
    );
    
    try {
      await _goalService.addGoal(goal);
      
      // 현재 월과 동일한 경우 현재 월 목표도 업데이트
      final now = DateTime.now();
      if (year == now.year && month == now.month) {
        await fetchCurrentMonthGoals();
      }
      
      // 선택한 월의 목표 업데이트
      await fetchGoalsByMonth(year, month);
    } catch (e) {
      print('특정 월 목표 추가 중 오류 발생: $e');
    }
  }

  // 월간 목표 완료 상태 변경
  Future<void> toggleGoalCompletion(String id) async {
    try {
      await _goalService.toggleGoalCompletion(id);
      await fetchCurrentMonthGoals();
      
      // 현재 선택된 월이 있다면 해당 월의 목표도 업데이트
      if (_monthlyGoals.isNotEmpty) {
        final sampleGoal = _monthlyGoals.first;
        await fetchGoalsByMonth(sampleGoal.year, sampleGoal.month);
      }
    } catch (e) {
      print('월간 목표 완료 상태 변경 중 오류 발생: $e');
    }
  }

  // 월간 목표 삭제
  Future<void> deleteGoal(String id) async {
    try {
      // 삭제 전에 목표 정보 저장
      final goals = await _goalService.getAllGoals();
      final goalToDelete = goals.firstWhere((g) => g.id == id);
      final year = goalToDelete.year;
      final month = goalToDelete.month;
      
      await _goalService.deleteGoal(id);
      await fetchCurrentMonthGoals();
      
      // 해당 월의 목표도 업데이트
      await fetchGoalsByMonth(year, month);
    } catch (e) {
      print('월간 목표 삭제 중 오류 발생: $e');
    }
  }

  // 월간 목표 업데이트
  Future<void> updateGoal(MonthlyGoal goal) async {
    try {
      await _goalService.updateGoal(goal);
      await fetchCurrentMonthGoals();
      
      // 해당 월의 목표도 업데이트
      await fetchGoalsByMonth(goal.year, goal.month);
    } catch (e) {
      print('월간 목표 업데이트 중 오류 발생: $e');
    }
  }
}