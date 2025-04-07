import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../providers/monthly_goal_provider.dart';
import '../widgets/todo_item.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 할 일'),
        elevation: 0,
        actions: [
          // 필터 버튼 추가
          Consumer<TodoProvider>(
            builder: (context, todoProvider, child) {
              return IconButton(
                icon: Icon(
                  todoProvider.showActiveOnly 
                    ? Icons.filter_alt 
                    : Icons.filter_alt_outlined,
                ),
                tooltip: todoProvider.showActiveOnly 
                  ? '모든 할 일 보기' 
                  : '남은 할 일만 보기',
                onPressed: () {
                  todoProvider.toggleShowActiveOnly();
                },
              );
            },
          ),
        ],
      ),
      body: Consumer2<TodoProvider, MonthlyGoalProvider>(
        builder: (context, todoProvider, goalProvider, child) {
          if (todoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // 현재 날짜 표시
              _buildDateHeader(),
              
              // 이번 달 목표 미리보기
              _buildMonthlyGoalPreview(context, goalProvider),
              
              // 할 일 목록
              _buildTodoList(context, todoProvider),
            ],
          );
        },
      ),
      // 새 할 일 추가 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // 날짜 헤더 위젯
  Widget _buildDateHeader() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy년 MM월 dd일 EEEE', 'ko_KR');
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        dateFormat.format(now),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 월간 목표 미리보기 위젯
  Widget _buildMonthlyGoalPreview(BuildContext context, MonthlyGoalProvider goalProvider) {
    return InkWell(
      onTap: () {
        // 월간 목표 화면으로 이동
        Navigator.pushNamed(context, '/monthly-goal');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '이번 달 목표',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${goalProvider.currentMonthGoals.length}개',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (goalProvider.currentMonthGoals.isEmpty)
              const Text(
                '목표를 설정해 보세요 (탭하여 이동)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < goalProvider.currentMonthGoals.length && i < 2; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            goalProvider.currentMonthGoals[i].isCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            size: 14,
                            color: goalProvider.currentMonthGoals[i].isCompleted
                                ? Colors.green
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              goalProvider.currentMonthGoals[i].content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                decoration: goalProvider.currentMonthGoals[i].isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: goalProvider.currentMonthGoals[i].isCompleted
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (goalProvider.currentMonthGoals.length > 2)
                    const Text(
                      '... 더 보기',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 할 일 목록 위젯
  Widget _buildTodoList(BuildContext context, TodoProvider todoProvider) {
    final todos = todoProvider.todayTodos;
    
    if (todos.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            '오늘 할 일이 없습니다.\n새 할 일을 추가해 보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return Expanded(
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false, // 드래그 핸들 사용하지 않음
        itemCount: todos.length,
        onReorder: (oldIndex, newIndex) {
          todoProvider.reorderTodayTodos(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          return ReorderableDelayedDragStartListener(
            key: Key(todos[index].id),
            index: index,
            child: TodoItem(
              todo: todos[index],
              onDelete: (id) => todoProvider.deleteTodo(id),
              onComplete: (id) => todoProvider.toggleCompleted(id),
              onPostpone: (id) => todoProvider.togglePostponed(id),
            ),
          );
        },
      ),
    );
  }

  // 새 할 일 추가 다이얼로그
  void _showAddTodoDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 할 일 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '할 일을 입력하세요',
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Provider.of<TodoProvider>(context, listen: false).addTodo(value);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<TodoProvider>(context, listen: false)
                    .addTodo(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}