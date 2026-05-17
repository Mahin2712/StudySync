import 'package:flutter/material.dart';
import '../../models/todo_model.dart';
import '../../services/todo_service.dart';
import '../../theme/app_colors.dart';

/// Compact, interactive to-do list widget for the dashboard sidebar.
class TodoListWidget extends StatefulWidget {
  const TodoListWidget({super.key});

  @override
  State<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends State<TodoListWidget> {
  List<TodoModel> _todos = [];
  bool _isLoading = true;
  final _controller = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    try {
      final todos = await TodoService.getTodos();
      if (mounted) setState(() => _todos = todos);
    } catch (_) {
      // silently handle
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addTodo() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 200) return;
    setState(() => _isAdding = true);
    try {
      final todo = await TodoService.addTodo(title: text);
      _controller.clear();
      if (mounted) {
        setState(() {
          _todos.insert(0, todo);
        });
      }
    } catch (_) {
      // silently handle
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _toggleTodo(TodoModel todo) async {
    final newState = !todo.isDone;
    // Optimistic update
    setState(() {
      final idx = _todos.indexWhere((t) => t.id == todo.id);
      if (idx >= 0) _todos[idx] = todo.copyWith(isDone: newState);
    });
    try {
      await TodoService.toggleTodo(todo.id, newState);
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          final idx = _todos.indexWhere((t) => t.id == todo.id);
          if (idx >= 0) _todos[idx] = todo;
        });
      }
    }
  }

  Future<void> _deleteTodo(TodoModel todo) async {
    setState(() => _todos.removeWhere((t) => t.id == todo.id));
    try {
      await TodoService.deleteTodo(todo.id);
    } catch (_) {
      // Reload on error
      _loadTodos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.checklist_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'To-Do List',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              _buildDoneCount(),
            ],
          ),
          const SizedBox(height: 12),

          // Add input
          _buildAddInput(),
          const SizedBox(height: 10),

          // List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (_todos.isEmpty)
            _buildEmptyState()
          else
            ..._todos.map(_buildTodoItem),
        ],
      ),
    );
  }

  Widget _buildDoneCount() {
    if (_todos.isEmpty) return const SizedBox.shrink();
    final done = _todos.where((t) => t.isDone).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: done == _todos.length
            ? AppColors.greenActive.withValues(alpha: 0.15)
            : AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$done/${_todos.length}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: done == _todos.length
              ? AppColors.greenActive
              : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildAddInput() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 34,
            child: TextField(
              controller: _controller,
              maxLength: 200,
              style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Add a task…',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
                counterText: '', // hide max length counter
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                filled: true,
                fillColor: AppColors.surfaceHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _addTodo(),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 34,
          height: 34,
          child: IconButton(
            onPressed: _isAdding ? null : _addTodo,
            padding: EdgeInsets.zero,
            icon: _isAdding
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'No tasks yet',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildTodoItem(TodoModel todo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleTodo(todo),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: todo.isDone
                    ? AppColors.greenActive.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: todo.isDone
                      ? AppColors.greenActive
                      : AppColors.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: todo.isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.greenActive,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              todo.title,
              style: TextStyle(
                fontSize: 12,
                color: todo.isDone
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
                decoration: todo.isDone ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Recurring indicator
          if (todo.isRecurring)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
                size: 12,
              ),
            ),
          // Delete
          SizedBox(
            width: 24,
            height: 24,
            child: IconButton(
              onPressed: () => _deleteTodo(todo),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
