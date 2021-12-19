import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app_riverpod/stats.dart';
import 'package:todo_app_riverpod/todo.dart';

void main() {
  runApp(ProviderScope(
    // observers: [Logger()],
    child: const MyApp(),
  ));
}

class Logger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('''
{
  "provider": "${provider.name ?? provider.runtimeType}",
  "newValue": "$newValue"
}''');
  }
}

final todosProvider =
    StateNotifierProvider<TodosList, List<Todo>>((ref) => TodosList([
          Todo(id: '1', description: 'todo1'),
          Todo(id: '2', description: 'todo2'),
          Todo(id: '3', description: 'todo3', completed: true),
        ]));

final filterProvider = StateProvider((ref) => Filter.all);

final filteredTodosProvider = Provider<List<Todo>>((ref) {
  List<Todo> todos = ref.watch(todosProvider);
  Filter filter = ref.watch(filterProvider);
  switch (filter) {
    case Filter.all:
      return todos;
    case Filter.completed:
      return todos.where((todo) => todo.completed).toList();
    case Filter.inProgress:
      return todos.where((todo) => !todo.completed).toList();
  }
});

final tabProvider = StateProvider<int>((ref) => 0);

final statsProvider = StateProvider<Stats>((ref) {
  int all = ref.watch(todosProvider).length;
  int completed =
      ref.watch(todosProvider).where((todo) => todo.completed).length;
  return Stats(all, completed);
});

enum Filter { all, completed, inProgress }

extension on Filter {
  String get string {
    switch (this) {
      case Filter.inProgress:
        return 'in progress';
      case Filter.all:
      case Filter.completed:
        return toString().split('.')[1];
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todos App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  MyHomePage({Key? key}) : super(key: key);
  final _todoController = TextEditingController();
  final _todoFocusNode = FocusNode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Todo> todos = ref.watch(filteredTodosProvider);
    Stats stats = ref.watch(statsProvider);
    int tab = ref.watch(tabProvider);
    return GestureDetector(
      onTap: () => _todoFocusNode.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Todos App'),
          actions: [
            if (tab == 0)
              PopupMenuButton<Filter>(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: 50, maxWidth: 100),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt),
                        SizedBox(width: 5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(ref.watch(filterProvider).string),
                        ),
                      ],
                    ),
                  ),
                  initialValue: ref.watch(filterProvider.notifier).state,
                  itemBuilder: (context) => Filter.values
                      .map((filter) => PopupMenuItem(
                            child: Text(filter.string),
                            value: filter,
                            onTap: () => ref
                                .read(filterProvider.notifier)
                                .state = filter,
                          ))
                      .toList()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Todos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calculate_outlined), label: 'Stats'),
          ],
          currentIndex: ref.watch(tabProvider),
          onTap: (value) => ref.read(tabProvider.state).state = value,
        ),
        body: ref.watch(tabProvider) != 0
            ? Theme(
                data: ThemeData(
                    textTheme: TextTheme(bodyText1: TextStyle(fontSize: 30))),
                child: Builder(builder: (context) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'All Todos: ${stats.all}',
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Completed Todos: ${stats.completed}',
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                      ],
                    ),
                  );
                }),
              )
            : ListView(padding: EdgeInsets.all(10), children: [
                TextField(
                  focusNode: _todoFocusNode,
                  controller: _todoController,
                  decoration: InputDecoration(
                    hintText: 'E.g. Do the shopping',
                    labelText: 'New Todo',
                  ),
                  onSubmitted: (_) {
                    ref
                        .read(todosProvider.notifier)
                        .addTodo(_todoController.text);
                    _todoController.clear();
                  },
                ),
                for (Todo todo in todos)
                  Dismissible(
                    key: Key(todo.id),
                    onDismissed: (_) =>
                        ref.read(todosProvider.notifier).removeTodo(todo),
                    child: CheckboxListTile(
                      value: todo.completed,
                      onChanged: (_) =>
                          ref.read(todosProvider.notifier).toggleTodo(todo),
                      title: Text(todo.description),
                      secondary: IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Edit Todo',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Divider(),
                                      TextFormField(
                                        autofocus: true,
                                        decoration: InputDecoration(
                                            focusedBorder: InputBorder.none),
                                        initialValue: todo.description,
                                        onFieldSubmitted: (val) {
                                          ref
                                              .read(todosProvider.notifier)
                                              .editTodo(todo.copyWith(
                                                  description: val));
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.edit)),
                    ),
                  )
              ]),
      ),
    );
  }
}
