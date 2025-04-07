import 'package:flutter/foundation.dart';
import '../models/todo_model.dart';
import '../services/todo_service.dart';
import 'package:intl/intl.dart';

class TodoProvider with ChangeNotifier {
  final TodoService _todoService = TodoService();
  
  List<Todo> _todayTodos = [];
  List<Todo> _tomorrowTodos = [];
  List<Todo> _selectedDateTodos = [];
  List<Todo> _allTodos = []; // 모든 할 일을 저장하기 위한 변수 추가
  bool _isLoading = false;
  bool _showActiveOnly = false; // 미완료 할 일만 표시할지 여부

  // Getters
  List<Todo> get todayTodos => _showActiveOnly ? 
      _todayTodos.where((todo) => !todo.isCompleted && !todo.isPostponed).toList() : 
      _todayTodos;
  List<Todo> get tomorrowTodos => _tomorrowTodos;
  List<Todo> get selectedDateTodos => _showActiveOnly ? 
      _selectedDateTodos.where((todo) => !todo.isCompleted && !todo.isPostponed).toList() : 
      _selectedDateTodos;
  List<Todo> get allTodos => _allTodos;
  bool get isLoading => _isLoading;
  bool get showActiveOnly => _showActiveOnly;
  
  // 필터 토글
  void toggleShowActiveOnly() {
    _showActiveOnly = !_showActiveOnly;
    notifyListeners();
  }

  // 초기화 함수
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await fetchAllTodos(); // 모든 할 일을 먼저 가져옴
      // 초기화 시 선택된 날짜는 오늘로 설정
      final now = DateTime.now();
      await fetchTodosByDate(now);
    } catch (e) {
      print('초기화 중 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 모든 할 일 가져오기
  Future<void> fetchAllTodos() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _allTodos = await _todoService.getAllTodos();
      
      // 오늘 날짜 생성
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      
      // 오늘과 내일 할 일 분리
      _todayTodos = _allTodos.where((todo) => 
        todo.date.year == today.year && 
        todo.date.month == today.month && 
        todo.date.day == today.day
      ).toList();
      
      _tomorrowTodos = _allTodos.where((todo) => 
        todo.date.year == tomorrow.year && 
        todo.date.month == tomorrow.month && 
        todo.date.day == tomorrow.day
      ).toList();
    } catch (e) {
      print('모든 할 일을 가져오는 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 오늘 할 일 가져오기
  Future<void> fetchTodayTodos() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _todayTodos = await _todoService.getTodayTodos();
      await fetchAllTodos(); // 모든 할 일도 함께 업데이트
    } catch (e) {
      print('오늘 할 일을 가져오는 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 내일 할 일 가져오기
  Future<void> fetchTomorrowTodos() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _tomorrowTodos = await _todoService.getTomorrowTodos();
      // 여기서는 fetchAllTodos를 호출하지 않음 - 순환 참조 문제 방지
    } catch (e) {
      print('내일 할 일을 가져오는 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 특정 날짜의 할 일 가져오기
  Future<void> fetchTodosByDate(DateTime date) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _selectedDateTodos = await _todoService.getTodosByDate(date);
    } catch (e) {
      print('선택한 날짜의 할 일을 가져오는 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 특정 날짜에 할 일이 있는지 비동기로 확인
  Future<bool> hasTodosOnDate(DateTime date) async {
    try {
      // 먼저 로컬 캐시에서 확인 (성능 향상을 위해)
      final hasTodosInCache = hasTodosOnDateSync(date);
      if (hasTodosInCache) {
        return true;
      }
      
      // 캐시에 없으면 서비스를 통해 확인
      final todos = await _todoService.getTodosByDate(date);
      return todos.isNotEmpty;
    } catch (e) {
      print('날짜에 할 일 확인 중 오류 발생: $e');
      return false;
    }
  }
  
  // 특정 날짜에 할 일이 있는지 비동기 없이 확인 (캐싱된 데이터만 사용)
  bool hasTodosOnDateSync(DateTime date) {
    // 전체 할 일 목록에서 확인
    return _allTodos.any((todo) => 
      todo.date.year == date.year && 
      todo.date.month == date.month && 
      todo.date.day == date.day
    );
  }

  // 새 할 일 추가
  Future<void> addTodo(String title) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: today,
    );
    
    try {
      await _todoService.addTodo(newTodo);
      await fetchTodayTodos();
      await fetchTodosByDate(today); // 오늘 날짜의 할 일도 업데이트
    } catch (e) {
      print('할 일 추가 중 오류 발생: $e');
    }
  }
  
  // 특정 날짜에 할 일 추가
  Future<void> addTodoOnDate(String title, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: normalizedDate,
    );
    
    try {
      await _todoService.addTodo(newTodo);
      await fetchAllTodos(); // 모든 할 일도 함께 업데이트
      
      // 선택한 날짜의 할 일 목록 업데이트
      await fetchTodosByDate(normalizedDate);
    } catch (e) {
      print('할 일 추가 중 오류 발생: $e');
    }
  }

  // 할 일 삭제
  Future<void> deleteTodo(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _todoService.deleteTodo(id);
      await _updateAllStates();
    } catch (e) {
      print('할 일 삭제 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 할 일 완료 상태 토글
  Future<void> toggleCompleted(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _todoService.toggleCompleted(id);
      
      // 종합 상태 업데이트
      await _updateAllStates();
    } catch (e) {
      print('할 일 완료 처리 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 할 일 미루기 상태 토글
  Future<void> togglePostponed(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _todoService.togglePostponed(id);
      
      // 종합 상태 업데이트
      await _updateAllStates();
    } catch (e) {
      print('할 일 미루기 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 현재 선택된 날짜에서 다음 날짜로 할 일 미루기
  Future<void> postponeToNextDay(String id) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 선택된 날짜가 있는 경우
      if (_selectedDateTodos.isNotEmpty) {
        final selectedDate = _selectedDateTodos.first.date;
        
        // 현재 날짜가 오늘인 경우
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        if (selectedDate.year == today.year && 
            selectedDate.month == today.month && 
            selectedDate.day == today.day) {
          // 오늘이면 토글 방식으로 내일로 미루기
          await _todoService.togglePostponed(id);
        } else {
          // 오늘이 아니면 해당 선택된 날짜의 다음 날짜로 미루기
          final nextDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1);
          await _todoService.postponeTodoToDate(id, nextDay);
        }
      } else {
        // 선택된 날짜가 없는 경우 기본적으로 내일로 미루기
        await _todoService.togglePostponed(id);
      }
      
      // 종합 상태 업데이트
      await _updateAllStates();
    } catch (e) {
      print('다음 날짜로 할 일 미루기 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 오늘 할 일 리스트 순서 변경
  Future<void> reorderTodayTodos(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final todoToMove = _todayTodos.removeAt(oldIndex);
    _todayTodos.insert(newIndex, todoToMove);
    
    // allTodos에서 해당 할 일들의 순서 변경
    final todayDate = DateTime.now();
    final today = DateTime(todayDate.year, todayDate.month, todayDate.day);
    
    // 전체 리스트에서 오늘 할 일들 제거
    _allTodos.removeWhere((todo) => 
      todo.date.year == today.year && 
      todo.date.month == today.month && 
      todo.date.day == today.day
    );
    
    // 순서가 조정된 할 일들 다시 추가
    _allTodos.addAll(_todayTodos);
    
    // 데이터 저장
    await _todoService.saveTodos(_allTodos);
    
    // UI 업데이트
    notifyListeners();
  }
  
  // 선택한 날짜의 할 일 리스트 순서 변경
  Future<void> reorderSelectedDateTodos(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    if (_selectedDateTodos.isEmpty) return;
    
    final selectedDate = _selectedDateTodos.first.date;
    final normalizedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final todoToMove = _selectedDateTodos.removeAt(oldIndex);
    _selectedDateTodos.insert(newIndex, todoToMove);
    
    // allTodos에서 해당 날짜의 할 일들 제거
    _allTodos.removeWhere((todo) => 
      todo.date.year == normalizedDate.year && 
      todo.date.month == normalizedDate.month && 
      todo.date.day == normalizedDate.day
    );
    
    // 순서가 조정된 할 일들 다시 추가
    _allTodos.addAll(_selectedDateTodos);
    
    // 데이터 저장
    await _todoService.saveTodos(_allTodos);
    
    // UI 업데이트
    notifyListeners();
  }
  
  // 특정 날짜로 할 일 미루기
  Future<void> postponeTodoToDate(String id, DateTime targetDate) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _todoService.postponeTodoToDate(id, targetDate);
      
      // 종합 상태 업데이트
      await _updateAllStates();
    } catch (e) {
      print('특정 날짜로 할 일 미루기 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 공통적으로 모든 상태를 업데이트하는 보조 메서드
  Future<void> _updateAllStates() async {
    try {
      // 필요한 데이터만 갱신 - 모든 상태를 한번에 가져오고 메모리에서 필터링
      final allTodos = await _todoService.getAllTodos();
      _allTodos = allTodos;
      
      // 오늘 날짜 생성
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      
      // 오늘과 내일 할 일 분리
      _todayTodos = allTodos.where((todo) => 
        todo.date.year == today.year && 
        todo.date.month == today.month && 
        todo.date.day == today.day
      ).toList();
      
      _tomorrowTodos = allTodos.where((todo) => 
        todo.date.year == tomorrow.year && 
        todo.date.month == tomorrow.month && 
        todo.date.day == tomorrow.day
      ).toList();
      
      // 현재 선택된 날짜의 할 일 갱신 - 추가 API 호출 없이 메모리에서 필터링
      if (_selectedDateTodos.isNotEmpty) {
        final selectedDate = _selectedDateTodos.first.date;
        final normalizedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        
        _selectedDateTodos = allTodos.where((todo) => 
          todo.date.year == normalizedDate.year && 
          todo.date.month == normalizedDate.month && 
          todo.date.day == normalizedDate.day
        ).toList();
      }
      
      // UI 업데이트 - 한 번만 호출
      notifyListeners();
    } catch (e) {
      print('상태 업데이트 중 오류 발생: $e');
    }
  }
  
  // 할 일 내용 수정
  Future<void> updateTodoTitle(String id, String newTitle) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _todoService.updateTodoTitle(id, newTitle);
      
      // 종합 상태 업데이트
      await _updateAllStates();
    } catch (e) {
      print('할 일 내용 수정 중 오류 발생: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}