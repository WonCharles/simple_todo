import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/todo_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final Function(String) onDelete;
  final Function(String) onComplete;
  final Function(String) onPostpone;

  const TodoItem({
    Key? key,
    required this.todo,
    required this.onDelete,
    required this.onComplete,
    required this.onPostpone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 성능 개선: 번번한 재로드 방지를 위해 Provider를 최소화하고 변경된 경우에만 상태 업데이트
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          // 미루기 액션
          SlidableAction(
            onPressed: (_) => onPostpone(todo.id),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            icon: Icons.schedule,
            label: '내일로',
          ),
          // 삭제 액션
          SlidableAction(
            onPressed: (_) => onDelete(todo.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
          ),
        ],
      ),
      
      child: Container(
        decoration: BoxDecoration(
          color: todo.isPostponed ? Colors.amber.withOpacity(0.1) : null,
          border: todo.isPostponed 
            ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1) 
            : null,
          borderRadius: todo.isPostponed ? BorderRadius.circular(8) : null,
        ),
        margin: todo.isPostponed ? const EdgeInsets.symmetric(vertical: 2) : null,
        child: ListTile(
          leading: Checkbox(
            value: todo.isCompleted,
            activeColor: Colors.green,
            onChanged: (value) {
              onComplete(todo.id);
            },
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted 
                ? Colors.grey 
                : (todo.isPostponed ? Colors.amber.shade800 : Colors.black87),
              fontWeight: todo.isPostponed ? FontWeight.w500 : null,
            ),
          ),
          subtitle: todo.isPostponed ? const Text('내일로 미루어짐', 
            style: TextStyle(fontSize: 12, color: Colors.amber, fontStyle: FontStyle.italic)) 
            : null,
          onTap: () {
            // 할 일이 완료되지 않았을 때만 수정 가능
            if (!todo.isCompleted) {
              _showEditTodoDialog(context, todo, todoProvider);
            }
          },
          trailing: SizedBox(
            width: 160,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 완료 버튼
                IconButton(
                  icon: Icon(
                    todo.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                    color: todo.isCompleted ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                  onPressed: () => onComplete(todo.id),
                  tooltip: '완료 토글',
                ),
                const SizedBox(width: 4),
                // 미루기 버튼 (완료된 할 일은 미루기 불가)
                IconButton(
                  icon: Icon(
                    Icons.schedule, 
                    color: todo.isPostponed ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                  onPressed: todo.isCompleted ? null : () {
                    print('미루기 버튼 누름 - 제목: ${todo.title}, 날짜: ${todo.date.toString()}');
                    onPostpone(todo.id);
                  },
                  tooltip: todo.isCompleted ? '완료된 항목은 미루기 불가' : '미루기 토글',
                ),
                const SizedBox(width: 4),
                // 삭제 버튼
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                  onPressed: () => onDelete(todo.id),
                  tooltip: '삭제',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 할 일 수정 다이얼로그
  void _showEditTodoDialog(BuildContext context, Todo todo, TodoProvider todoProvider) {
    final TextEditingController controller = TextEditingController(text: todo.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '할 일을 입력하세요',
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.isNotEmpty && value != todo.title) {
              todoProvider.updateTodoTitle(todo.id, value);
              Navigator.pop(context);
            } else if (value.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('내용을 입력해주세요'),
                duration: Duration(seconds: 2)),
              );
            } else {
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
              if (controller.text.isNotEmpty && controller.text != todo.title) {
                todoProvider.updateTodoTitle(todo.id, controller.text);
                Navigator.pop(context);
              } else if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('내용을 입력해주세요'),
                  duration: Duration(seconds: 2)),
                );
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }
}