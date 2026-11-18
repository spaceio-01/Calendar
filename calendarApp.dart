import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});

  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  Locale _locale = const Locale('ko');

  void _toggleLanguage() {
    setState(() {
      _locale = _locale.languageCode == 'ko'
          ? const Locale('en')
          : const Locale('ko');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'Calendar',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: CalendarPage(onToggleLanguage: _toggleLanguage),
    );
  }
}

class CalendarPage extends StatefulWidget {
  final VoidCallback onToggleLanguage;

  const CalendarPage({super.key, required this.onToggleLanguage});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<String>> _events = {};

  List<String> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  String _formatNumber(int number) {
    return number.toString().padLeft(2, '0');
  }

  void _addEvent() {
    final controller = TextEditingController();
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isKo ? '새 일정' : 'New Event'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: isKo ? '일정 제목' : 'Event Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final key = DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                );
                setState(() {
                  _events.putIfAbsent(key, () => []);
                  _events[key]!.add(controller.text.trim());
                });
              }
              Navigator.pop(context);
            },
            child: Text(isKo ? '추가' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _editEvent(int index, String currentText) {
    final controller = TextEditingController(text: currentText);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isKo ? '일정 수정' : 'Edit Event'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: isKo ? '일정 제목' : 'Event Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isKo ? '취소' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final key = DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                );
                setState(() {
                  _events[key]?[index] = controller.text.trim();
                });
              }
              Navigator.pop(context);
            },
            child: Text(isKo ? '저장' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(int index) {
    final key = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    setState(() {
      _events[key]?.removeAt(index);
      if (_events[key]?.isEmpty ?? false) {
        _events.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDay);
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '달력' : 'Calendar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: widget.onToggleLanguage,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: Localizations.localeOf(context).languageCode,
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isKo
                ? '선택된 날짜: ${_selectedDay.year}.${_formatNumber(_selectedDay.month)}.${_formatNumber(_selectedDay.day)}'
                : 'Selected date: ${_formatNumber(_selectedDay.month)}/${_formatNumber(_selectedDay.day)}/${_selectedDay.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      isKo ? '이 날짜에는 일정이 없습니다' : 'No events for this date',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    itemBuilder: (_, index) {
                      final eventText = events[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.event, color: Colors.blue),
                          title: Text(eventText),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () => _editEvent(index, eventText),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteEvent(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
