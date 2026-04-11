import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/widgets/feedback/error_state.dart';

/// Generic async-loading page that handles loading/error/data states.
///
/// Eliminates the duplicated `state.when(loading: ..., error: ..., data: ...)`
/// Scaffold boilerplate across route-facing page wrappers.
class AsyncPage<T> extends StatelessWidget {
  const AsyncPage({
    required this.title,
    required this.state,
    required this.onRetry,
    required this.builder,
    super.key,
  });

  /// App bar title shown during loading and error states.
  final String title;

  /// The async state to observe.
  final AsyncValue<T> state;

  /// Retry callback for error state.
  final VoidCallback onRetry;

  /// Builds the content when data is available.
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading:
          () => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (_, _) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: ErrorState(onRetry: onRetry),
          ),
      data: builder,
    );
  }
}
