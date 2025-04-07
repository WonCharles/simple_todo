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