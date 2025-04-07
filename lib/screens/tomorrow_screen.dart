import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';

class TomorrowScreen extends StatelessWidget {
  const TomorrowScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내일 할 일'),
        elevation: 0,
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          return Column(
            children: [
              // 내일 날짜 표시
              _buildDateHeader(),
              
              // 할 일 목록
              _buildTodoList(context, todoProvider),
            ],
          );
        },
      ),
    );
  }

  // 날짜 헤더 위젯
  Widget _buildDateHeader() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateFormat = DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR');
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        dateFormat.format(tomorrow),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 할 일 목록 위젯
  Widget _buildTodoList(BuildContext context, TodoProvider todoProvider) {
    final todos = todoProvider.tomorrowTodos;
    
    if (todos.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            '내일 할 일이 없습니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return Expanded(
      child: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          return TodoItem(
            todo: todos[index],
            onDelete: (id) => todoProvider.deleteTodo(id),
            onComplete: (id) => todoProvider.toggleCompleted(id),
            onPostpone: (id) {}, // 이미 내일로 미뤄진 항목이므로 이 기능은 비활성화
          );
        },
      ),
    );
  }
}