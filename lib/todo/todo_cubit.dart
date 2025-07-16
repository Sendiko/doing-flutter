import 'package:dio/dio.dart';
import 'package:doing_flutter/todo/todo_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;

  const TodoLoaded(this.todos);

  @override
  List<Object> get props => [todos];
}

class TodoError extends TodoState {
  final String message;

  const TodoError(this.message);

  @override
  List<Object> get props => [message];
}

class TodoCubit extends Cubit<TodoState> {
  final Dio _dio = Dio()
    ..interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ),
    );

  TodoCubit() : super(TodoInitial());

  Future<void> fetchTodos() async {
    try {
      emit(TodoLoading());

      final url = 'https://doingflutter.sendiko.my.id/todos';

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final todos = data.map((element) => Todo.fromJson(element)).toList();

        emit(TodoLoaded(todos));
      } else {
        emit(
          TodoError(
            'Failed to fetch todos. Status code: ${response.statusCode}',
          ),
        );
      }
    } on DioException catch (e) {
      emit(TodoError('An error occured with Dio: $e'));
    } catch (e) {
      emit(TodoError('An error occured: $e'));
    }
  }

  Future<void> addTodo(String title) async {
    final url = 'https://doingflutter.sendiko.my.id/todos';
    try {
      final response = await _dio.post(
        url,
        data: {'title': title, 'completed': false},
      );

      if (response.statusCode == 201) {
        fetchTodos();
      } else {
        emit(TodoError('Failed to add todo: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      emit(TodoError('An error occured with Dio: $e'));
    } catch (e) {
      emit(TodoError('An error occurred while adding todo: $e'));
    }
  }

  Future<void> updateTodo(Todo todo) async {
    final url = 'https://doingflutter.sendiko.my.id/todos/${todo.id}';
    try {
      final response = await _dio.put(
        url,
        data: {'title': todo.title, 'completed': !todo.completed},
      );

      if (response.statusCode == 200 && state is TodoLoaded) {
        final currentState = state as TodoLoaded;
        final updatedTodos = currentState.todos.map((t) {
          return t.id == todo.id ? t.copyWith(completed: !t.completed) : t;
        }).toList();
        emit(TodoLoaded(updatedTodos));
      } else {
        emit(
          TodoError(
            'Failed to update todo. Status code: ${response.statusCode}',
          ),
        );
      }
    } on DioException catch (e) {
      emit(TodoError('An error occured with Dio: $e'));
    } catch (e) {
      emit(TodoError('An error occurred while updating: $e'));
    }
  }

  Future<void> deleteTodo(int id) async {
    final url = 'https://doingflutter.sendiko.my.id/todos/$id';
    try {
      final response = await _dio.delete(url);

      if (response.statusCode == 204 && state is TodoLoaded) {
        final currentState = state as TodoLoaded;
        final updatedTodos = currentState.todos
            .where((t) => t.id != id)
            .toList();
        emit(TodoLoaded(updatedTodos));
      } else {
        emit(TodoError('Failed to delete todo.'));
      }
    } on DioException catch (e) {
      emit(TodoError('An error occured with Dio: $e'));
    } catch (e) {
      emit(TodoError('An error occurred while deleting: $e'));
    }
  }
}
