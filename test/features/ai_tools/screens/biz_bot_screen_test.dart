import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bizagent/features/ai_tools/screens/biz_bot_screen.dart';
import 'package:bizagent/core/services/enhanced_ai_service.dart';

@GenerateNiceMocks([MockSpec<EnhancedAIService>()])
import 'biz_bot_screen_test.mocks.dart';

void main() {
  late MockEnhancedAIService mockAIService;

  setUp(() {
    mockAIService = MockEnhancedAIService();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [enhancedAIServiceProvider.overrideWithValue(mockAIService)],
      child: const MaterialApp(home: BizBotScreen()),
    );
  }

  testWidgets('BizBotScreen displays welcome message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.textContaining('Ahoj! Som tvoj BizAgent'), findsOneWidget);
    expect(find.text('BizBot'), findsOneWidget);
  });

  testWidgets('Sending a message displays user message and AI response', (
    WidgetTester tester,
  ) async {
    // Arrange
    when(
      mockAIService.askBizBot(any),
    ).thenAnswer((_) async => 'Odpoveď AI na test');

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Act - Enter text
    await tester.enterText(
      find.byKey(const Key('bizbot_input')),
      'Testovacia otázka',
    );
    await tester.tap(find.byKey(const Key('bizbot_send_btn')));

    // Re-render
    await tester.pump(); // Start animation
    expect(
      find.text('Testovacia otázka'),
      findsOneWidget,
    ); // User message should be visible immediately

    // Finish async gap
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Odpoveď AI na test'), findsOneWidget);
    verify(mockAIService.askBizBot('Testovacia otázka')).called(1);
  });

  testWidgets('Suggested prompts populate input and send message', (
    WidgetTester tester,
  ) async {
    // Arrange
    const suggestion = 'Ako vystavím faktúru?';
    when(
      mockAIService.askBizBot(any),
    ).thenAnswer((_) async => 'Takto vystavíš faktúru...');

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Act - Tap suggestion chip
    await tester.tap(find.text(suggestion));

    // Re-render
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text(suggestion),
      findsOneWidget,
    ); // Should appear as user message
    expect(
      find.text('Takto vystavíš faktúru...'),
      findsOneWidget,
    ); // AI response
    verify(mockAIService.askBizBot(suggestion)).called(1);
  });

  testWidgets('Shows error message when service fails', (
    WidgetTester tester,
  ) async {
    // Arrange
    when(mockAIService.askBizBot(any)).thenThrow(Exception('network error'));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(find.byKey(const Key('bizbot_input')), 'Fail me');
    await tester.tap(find.byKey(const Key('bizbot_send_btn')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('Sieťová chyba'), findsOneWidget);
  });
}
