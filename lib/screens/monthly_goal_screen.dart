import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/monthly_goal_provider.dart';
import '../widgets/monthly_goal_item.dart';
import '../models/monthly_goal_model.dart';

class MonthlyGoalScreen extends StatefulWidget {
  const MonthlyGoalScreen({Key? key}) : super(key: key);

  @override
  State<MonthlyGoalScreen> createState() => _MonthlyGoalScreenState();
}

class _MonthlyGoalScreenState extends State<MonthlyGoalScreen> {
  DateTime _selectedMonth = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    // 선택한 월의 목표 목록 가져오기
    _fetchSelectedMonthGoals();
  }
  
  void _fetchSelectedMonthGoals() {
    final goalProvider = Provider.of<MonthlyGoalProvider>(context, listen: false);
    goalProvider.fetchGoalsByMonth(_selectedMonth.year, _selectedMonth.month);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이번 달 목표'),
        elevation: 0,
      ),
      body: Consumer<MonthlyGoalProvider>(
        builder: (context, goalProvider, child) {
          if (goalProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 월경 포맷
          final monthFormat = DateFormat('yyyy년 MM월', 'ko_KR');
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 현재 연월 표시 및 이동 버튼
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                        setState(() {
                          // 이전 월로 이동
                        _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month - 1,
                      1
                    );
                    _fetchSelectedMonthGoals();
                    });
                    },
                    ),
                    Text(
                        monthFormat.format(_selectedMonth),
                        style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                    ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                        setState(() {
                          // 다음 월로 이동
                        _selectedMonth = DateTime(
                        _selectedMonth.year,
                        _selectedMonth.month + 1,
                      1
                    );
                    _fetchSelectedMonthGoals();
                    });
                    },
                    ),
                    ],
                    ),
                    const SizedBox(height: 8),
                    
                    // 목표 개수 표시
                    Text(
                      '총 ${goalProvider.monthlyGoals.length}개의 목표',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 목표 목록
              Expanded(
                child: goalProvider.monthlyGoals.isEmpty
                    ? Center(
                        child: Text(
                          '${monthFormat.format(_selectedMonth)}에 등록된 목표가 없습니다.\n새 목표를 추가해보세요!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: goalProvider.monthlyGoals.length,
                        itemBuilder: (context, index) {
                          return MonthlyGoalItem(
                            goal: goalProvider.monthlyGoals[index],
                            onDelete: (id) => goalProvider.deleteGoal(id),
                            onToggleCompletion: (id) => goalProvider.toggleGoalCompletion(id),
                            onEdit: (goal) => goalProvider.updateGoal(goal),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      // 새 목표 추가 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 새 목표 추가 다이얼로그
  void _showAddGoalDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 목표 추가'),
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
                Provider.of<MonthlyGoalProvider>(context, listen: false)
                    .addGoalForMonth(controller.text, _selectedMonth.year, _selectedMonth.month);
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