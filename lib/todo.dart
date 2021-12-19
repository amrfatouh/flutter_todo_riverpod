import 'package:flutter/cupertino.dart';
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

class TodosList extends ChangeNotifier {
  final _uuid = Uuid();
  List<Todo> todos;
  TodosList([this.todos = const []]);

  void addTodo(String description) {
    // todos = [...todos, Todo(id: _uuid.v4(), description: description)];
    todos.add(Todo(id: _uuid.v4(), description: description));
    notifyListeners();
  }

  void removeTodo(Todo todo) {
    // todos = todos.where((td) => td.id != todo.id).toList();
    todos.removeWhere((td) => td.id == todo.id);
    notifyListeners();
  }

  void editTodo(Todo todo) {
    int index = todos.indexWhere((td) => td.id == todo.id);
    todos.replaceRange(index, index + 1, [todo]);
    notifyListeners();
    // todos = todos.map((td) {
    //   if (td.id != todo.id) {
    //     return td.copyWith();
    //   } else {
    //     return todo.copyWith();
    //   }
    // }).toList();
  }

  void toggleTodo(Todo todo) {
    editTodo(todo.copyWith(completed: !todo.completed));
  }
}
