import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterCubit extends Cubit<int> {
  _CounterCubit() : super(0);
}

class _CounterView extends BaseView<_CounterCubit, int> {
  const _CounterView();

  @override
  PreferredSizeWidget appBar(BuildContext context, int state) =>
      AppBar(title: const Text('Counter'));

  @override
  Widget body(BuildContext context, int state) => Text('Count: $state');

  @override
  Widget? floatingActionButton(BuildContext context, int state) =>
      FloatingActionButton(onPressed: () => cubitOf(context).emit(state + 1));
}

void main() {
  testWidgets('BaseView renders appBar, body, and floatingActionButton', (
    tester,
  ) async {
    final cubit = _CounterCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<_CounterCubit>.value(
          value: cubit,
          child: const _CounterView(),
        ),
      ),
    );

    expect(find.text('Counter'), findsOneWidget);
    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
    await cubit.close();
  });
}
