import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'todo.freezed.dart';

@freezed
class Todo with _$Todo {
  const factory Todo(
      {required String id,
      required String description,
      @Default(false) bool completed}) = _Todo;
}

class TodosList extends StateNotifier<List<Todo>> {
  final _uuid = Uuid();
  TodosList([List<Todo> initialTodo = const []]) : super(initialTodo);

  void addTodo(String description) {
    state = [...state, Todo(id: _uuid.v4(), description: description)];
  }

  void removeTodo(Todo todo) {
    state = state.where((td) => td.id != todo.id).toList();
  }

  void editTodo(Todo todo) {
    state = state.map((td) {
      if (td.id != todo.id) {
        return td.copyWith();
      } else {
        return todo.copyWith();
      }
    }).toList();
  }

  void toggleTodo(Todo todo) {
    editTodo(todo.copyWith(completed: !todo.completed));
  }
}
