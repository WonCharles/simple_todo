import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';

class TodoService {
  static const String _todosKey = 'todos';
  
  // 메모리 캐시
  List<Todo>? _cachedTodos;
  DateTime? _lastCacheUpdate;
  
  // 캐시 초기화
  void invalidateCache() {
    _cachedTodos = null;
    _lastCacheUpdate = null;
  }
  
  // 캐시 유효성 여부 확인 (초단위 기준 5초)
  bool _isCacheValid() {
    if (_cachedTodos == null || _lastCacheUpdate == null) return false;
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!).inSeconds < 5;
  }

  // 모든 할 일을 가져오는 함수
  Future<List<Todo>> getAllTodos() async {
    try {
      // 캐시가 유효하면 캐시된 데이터 반환
      if (_isCacheValid() && _cachedTodos != null) {
        print('캐시된 데이터 사용');
        return List<Todo>.from(_cachedTodos!);
      }
      
      // 새로 데이터 불러오기
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getStringList(_todosKey) ?? [];
      
      final todos = todosJson
          .map((todoJson) => Todo.fromJson(jsonDecode(todoJson)))
          .toList();
      
      // 캐시 업데이트
      _cachedTodos = List<Todo>.from(todos);
      _lastCacheUpdate = DateTime.now();
      
      return todos;
    } catch (e) {
      print('모든 할 일 가져오기 중 오류 발생: $e');
      // 오류 발생 시 캐시가 있으면 캐시 사용
      if (_cachedTodos != null) {
        return List<Todo>.from(_cachedTodos!);
      }
      return []; // 오류 발생 시 빈 리스트 반환
    }
  }

  // 특정 날짜의 할 일을 가져오는 함수
  Future<List<Todo>> getTodosByDate(DateTime date) async {
    final todos = await getAllTodos();
    final filteredTodos = todos.where((todo) {
      return todo.date.year == date.year &&
          todo.date.month == date.month &&
          todo.date.day == date.day;
    }).toList();
    
    return filteredTodos;
  }

  // 오늘 할 일 가져오기
  Future<List<Todo>> getTodayTodos() async {
    return getTodosByDate(DateTime.now());
  }

  // 내일 할 일 가져오기
  Future<List<Todo>> getTomorrowTodos() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return getTodosByDate(tomorrow);
  }

  // 새 할 일 추가
  Future<void> addTodo(Todo todo) async {
    final todos = await getAllTodos();
    todos.add(todo);
    await _saveTodos(todos);
  }

  // 할 일 업데이트
  Future<void> updateTodo(Todo updatedTodo) async {
    final todos = await getAllTodos();
    final index = todos.indexWhere((todo) => todo.id == updatedTodo.id);
    
    if (index != -1) {
      todos[index] = updatedTodo;
      await _saveTodos(todos);
    }
  }
  
  // 할 일 제목/내용만 업데이트 (상태 변경 없이)
  Future<void> updateTodoTitle(String id, String newTitle) async {
    final todos = await getAllTodos();
    final index = todos.indexWhere((todo) => todo.id == id);
    
    if (index != -1) {
      todos[index] = todos[index].copyWith(title: newTitle);
      await _saveTodos(todos);
    }
  }

  // 할 일 삭제
  Future<void> deleteTodo(String id) async {
    final todos = await getAllTodos();
    final todoIndex = todos.indexWhere((todo) => todo.id == id);
    
    if (todoIndex != -1) {
      // 삭제할 할 일 정보 저장
      final todoToDelete = todos[todoIndex];
      
      // 해당 할 일이 미루기로 추가된 할 일인지 확인
      final isPostponedTodo = id.contains('_postponed_');
      
      // 미루기로 추가된 할 일이 아닌 경우에만 연결된 할 일도 삭제
      if (!isPostponedTodo) {
        // 해당 할 일과 연결된 미루기 할 일도 삭제
        todos.removeWhere((item) => 
          item.id.startsWith('${todoToDelete.id}_postponed_'));
      }
      
      // 해당 할 일 삭제
      todos.removeAt(todoIndex);
      
      await _saveTodos(todos);
    }
  }

  // 할 일을 완료 상태로 토글
  Future<void> toggleCompleted(String id) async {
    final todos = await getAllTodos();
    final index = todos.indexWhere((todo) => todo.id == id);
    
    if (index != -1) {
      final todo = todos[index];
      final wasPostponed = todo.isPostponed;
      final isNowCompleted = !todo.isCompleted;
      
      // 완료 상태 토글
      todos[index] = todos[index].copyWith(
        isCompleted: isNowCompleted,
        // 완료로 변경하면 미루기 상태는 항상 해제
        isPostponed: isNowCompleted ? false : todos[index].isPostponed
      );
      
      // 할 일이 완료되고 이전에 미루기 상태였다면 내일 할 일에서 제거
      if (isNowCompleted && wasPostponed) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final postponedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
        
        // 내일 할 일 목록에서 같은 제목을 가진 할 일 제거
        todos.removeWhere((existingTodo) => 
          existingTodo.title == todo.title && 
          existingTodo.date.year == postponedDate.year &&
          existingTodo.date.month == postponedDate.month &&
          existingTodo.date.day == postponedDate.day);
      }
      
      await _saveTodos(todos);
    }
  }

  // 할 일을 미루기 상태 토글
  Future<void> togglePostponed(String id) async {
    final todos = await getAllTodos();
    final index = todos.indexWhere((todo) => todo.id == id);
    
    if (index != -1) {
      final todo = todos[index];
      final isCurrentlyPostponed = todo.isPostponed;
      
      // 미루기 상태 토글
      todos[index] = todo.copyWith(
        isPostponed: !isCurrentlyPostponed,
        // 미루기로 변경하면 완료 상태는 해제
        isCompleted: !isCurrentlyPostponed ? false : todo.isCompleted
      );
      
      // 미루기를 취소하는 경우, 내일로 미룬 할 일 삭제
      if (isCurrentlyPostponed) {
        // 내일 목록에서 미루어진 항목 찾아 제거
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final postponedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
        
        // 삭제할 내일 할 일 찾기 (같은 제목의 할 일)
        todos.removeWhere((existingTodo) => 
          existingTodo.title == todo.title && 
          existingTodo.date.year == postponedDate.year &&
          existingTodo.date.month == postponedDate.month &&
          existingTodo.date.day == postponedDate.day);
      } else {
        // 미루기를 실행하는 경우, 내일에 할 일 추가
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1); // 정확하게 내일 날짜 계산
        
        // 같은 제목의 할 일이 이미 내일 추가되어 있는지 확인
        bool alreadyExists = todos.any((existingTodo) => 
          existingTodo.title == todo.title && 
          existingTodo.date.year == tomorrow.year &&
          existingTodo.date.month == tomorrow.month &&
          existingTodo.date.day == tomorrow.day);
        
        // 내일 목록에 없을 경우에만 추가
        if (!alreadyExists) {
          // 내일 할 일로 새 항목 추가
          final newTodo = Todo(
            id: '${todo.id}_postponed_${DateTime.now().millisecondsSinceEpoch}',
            title: todo.title,
            date: tomorrow,
          );
          
          todos.add(newTodo);
          print('내일로 미루기 실행: ${todo.title} - ${tomorrow.toString()}');
        }
      }
      
      await _saveTodos(todos);
    }
  }

  // 특정 날짜로 할 일 미루기
  Future<void> postponeTodoToDate(String id, DateTime targetDate) async {
    final todos = await getAllTodos();
    final index = todos.indexWhere((todo) => todo.id == id);
    
    if (index != -1) {
      final todo = todos[index];
      
      // 원래 할 일이 미루기 상태였는지 확인
      final wasPostponed = todo.isPostponed;
      
      // 상태 업데이트: 미루기 상태로 변경하고 완료 상태 해제
      todos[index] = todo.copyWith(
        isPostponed: true,
        isCompleted: false
      );
      
      // 같은 제목의 할 일이 이미 해당 날짜에 있는지 확인
      bool alreadyExists = todos.any((existingTodo) => 
        existingTodo.title == todo.title && 
        existingTodo.date.year == targetDate.year &&
        existingTodo.date.month == targetDate.month &&
        existingTodo.date.day == targetDate.day);
      
      // 이미 존재하지 않는 경우에만 추가
      if (!alreadyExists) {
        // 해당 날짜로 할 일 추가
        final newTodo = Todo(
          id: '${todo.id}_postponed_${DateTime.now().millisecondsSinceEpoch}',
          title: todo.title,
          date: targetDate,
        );
        
        todos.add(newTodo);
      }
      
      await _saveTodos(todos);
    }
  }

  // 모든 할 일 저장 (private에서 public으로 변경)
  Future<void> saveTodos(List<Todo> todos) async {
    return _saveTodos(todos);
  }
  
  // 모든 할 일 저장 (내부용)
  Future<void> _saveTodos(List<Todo> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = todos.map((todo) => jsonEncode(todo.toJson())).toList();
      await prefs.setStringList(_todosKey, todosJson);
      
      // 캐시 무효화
      invalidateCache();
    } catch (e) {
      print('할 일 저장 중 오류 발생: $e');
      throw e; // 오류를 상위로 전파하여 프로바이더에서 처리할 수 있게함
    }
  }
}