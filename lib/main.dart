import 'dart:convert';

import 'package:doing_flutter/add_item_screen.dart';
import 'package:doing_flutter/todo_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(), // Our starting screen
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodos(); // Fetch todos when the screen is initialized
  }

  Future<void> _fetchTodos() async {
    final uri = Uri.parse('https://doingflutter.sendiko.my.id/todos');
    print('Fetching data from: $uri');
    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _todos = data.map((item) => Todo.fromJson(item)).toList();
          _isLoading = false;
        });
        print('Data fetched and parsed successfully!'); // <-- ADD THIS
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Server error: ${response.statusCode}'); // <-- ADD THIS
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('An error occurred: $e'); // <-- ADD THIS
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API To Do List'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
          if (result == true) {
            setState(() {
              _isLoading = true;
            });
            _fetchTodos();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return ListTile(
                  title: Text(todo.title),
                  leading: CircleAvatar(child: Text(todo.id.toString())),
                  trailing: Icon(
                    todo.completed ? Icons.check_circle : Icons.circle,
                    color: todo.completed ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
    );
  }
}
