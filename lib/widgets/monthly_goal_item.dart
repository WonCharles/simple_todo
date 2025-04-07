import 'package:flutter/material.dart';
import '../models/monthly_goal_model.dart';

class MonthlyGoalItem extends StatelessWidget {
  final MonthlyGoal goal;
  final Function(String) onDelete;
  final Function(String) onToggleCompletion;
  final Function(MonthlyGoal) onEdit;

  const MonthlyGoalItem({
    Key? key,
    required this.goal,
    required this.onDelete,
    required this.onToggleCompletion,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 완료 체크박스
            Checkbox(
              value: goal.isCompleted,
              onChanged: (value) {
                onToggleCompletion(goal.id);
              },
            ),
            const SizedBox(width: 8),
            
            // 목표 내용
            Expanded(
              child: Text(
                goal.content,
                style: TextStyle(
                  fontSize: 16,
                  decoration: goal.isCompleted ? TextDecoration.lineThrough : null,
                  color: goal.isCompleted ? Colors.grey : Colors.black87,
                ),
              ),
            ),
            
            // 편집 버튼
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDialog(context),
            ),
            
            // 삭제 버튼
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => onDelete(goal.id),
            ),
          ],
        ),
      ),
    );
  }

  // 편집 다이얼로그
  void _showEditDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: goal.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표 수정'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '목표를 입력하세요',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onEdit(goal.copyWith(content: controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}