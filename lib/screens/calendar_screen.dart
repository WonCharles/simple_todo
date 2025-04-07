import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';
import '../models/todo_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _focusedMonth;
  
  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    
    // 캩8린더 초기화시 모든 할 일 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TodoProvider>(context, listen: false).fetchAllTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('할 일 달력'),
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
      body: Column(
        children: [
          // 달력 헤더
          _buildCalendarHeader(),
          
          // 요일 헤더
          _buildWeekdayHeader(),
          
          // 달력 그리드
          _buildCalendarGrid(),
          
          // 선택한 날짜 표시
          _buildSelectedDateHeader(),
          
          // 선택한 날짜의 할 일 목록
          _buildTodoListForSelectedDate(),
        ],
      ),
      // 새 할 일 추가 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // 달력 헤더 (월 이동 버튼)
  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                  1,
                );
              });
              // 성능 개선: 날짜 변경시 새로운 데이터만 가져오기
              // 댌어간 공통 개선에서 이미 코드가 업데이트되어 혹시라도 변경이 필요한 경우에만 갱신
              Provider.of<TodoProvider>(context, listen: false).fetchAllTodos();
            },
          ),
          Text(
            DateFormat('yyyy년 MM월').format(_focusedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                  1,
                );
              });
              // 성능 개선: 날짜 변경시 새로운 데이터만 가져오기
              Provider.of<TodoProvider>(context, listen: false).fetchAllTodos();
            },
          ),
        ],
      ),
    );
  }

  // 요일 헤더
  Widget _buildWeekdayHeader() {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        final isWeekend = day == '일';
        final isSaturday = day == '토';
        
        Color textColor;
        if (isWeekend) {
          textColor = Colors.red;
        } else if (isSaturday) {
          textColor = Colors.blue;
        } else {
          textColor = Colors.black87;
        }
        
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 달력 그리드
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final dayOffset = firstDayOfMonth.weekday % 7; // 0이 일요일이 되도록
    
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final totalCells = ((dayOffset + daysInMonth) / 7).ceil() * 7;
    
    // 성능 개선: UI 갱신을 위한 소비자 패턴 사용
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        // GridView는 한 번만 생성
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 50,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final adjustedIndex = index - dayOffset;
              
              if (adjustedIndex < 0 || adjustedIndex >= daysInMonth) {
                return const SizedBox.shrink();
              }
              
              final day = adjustedIndex + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isToday = _isToday(date);
              final isSelected = _isSameDay(date, _selectedDate);
              final isSunday = date.weekday == DateTime.sunday;
              final isSaturday = date.weekday == DateTime.saturday;
              
              Color textColor;
              if (isSunday) {
                textColor = Colors.red;
              } else if (isSaturday) {
                textColor = Colors.blue;
              } else {
                textColor = Colors.black87;
              }
              
              // 소비자 패턴에서 가져온 모든 할 일
              final allTodos = todoProvider.allTodos;
              
              // 해당 날짜에 할 일이 있는지 확인 - 메모리에서 필터링
              final hasTodos = allTodos.any((todo) => 
                todo.date.year == date.year && 
                todo.date.month == date.month && 
                todo.date.day == date.day
              );
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  // 해당 날짜의 할 일 목록 가져오기
                  todoProvider.fetchTodosByDate(date);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.blue.withOpacity(0.2) 
                        : (isToday ? Colors.amber.withOpacity(0.1) : null),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected 
                        ? Border.all(color: Colors.blue) 
                        : (isToday ? Border.all(color: Colors.amber) : null),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: isToday || isSelected ? FontWeight.bold : null,
                          color: textColor,
                        ),
                      ),
                      if (hasTodos)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSunday ? Colors.red.shade300 : Colors.blue,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 선택한 날짜 헤더
  Widget _buildSelectedDateHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.centerLeft,
      child: Text(
        DateFormat('yyyy년 MM월 dd일 EEEE').format(_selectedDate),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 선택한 날짜의 할 일 목록
  Widget _buildTodoListForSelectedDate() {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        if (todoProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final todos = todoProvider.selectedDateTodos;
        
        if (todos.isEmpty) {
          return const Expanded(
            child: Center(
              child: Text(
                '이 날의 할 일이 없습니다.\n새 할 일을 추가해 보세요!',
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
              todoProvider.reorderSelectedDateTodos(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              return ReorderableDelayedDragStartListener(
                key: Key(todos[index].id),
                index: index,
                child: TodoItem(
                  todo: todos[index],
                  onDelete: (id) => todoProvider.deleteTodo(id),
                  onComplete: (id) => todoProvider.toggleCompleted(id),
                  onPostpone: (id) => todoProvider.postponeToNextDay(id),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  // 오늘 날짜인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // 같은 날인지 확인
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  // 새 할 일 추가 다이얼로그
  void _showAddTodoDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${DateFormat('MM월 dd일').format(_selectedDate)}의 할 일 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '할 일을 입력하세요',
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Provider.of<TodoProvider>(context, listen: false)
                  .addTodoOnDate(value, _selectedDate);
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
                    .addTodoOnDate(controller.text, _selectedDate);
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