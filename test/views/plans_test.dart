import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzeria_totos/core/theme/toto_theme.dart';
import 'package:pizzeria_totos/views/subscription/plan_card.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('La Fija muestra imagen, ahorro y CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: totoTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlanCard(
              plan: samplePlans[1],
              onTap: () {},
              onChoose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('LA FIJA'), findsOneWidget);
    expect(find.text('MEJOR PRECIO'), findsOneWidget);
    expect(find.text('S/ 39.90'), findsOneWidget);
    expect(find.text('Ahorras S/ 4.80'), findsOneWidget);
    expect(find.text('ELEGIR LA FIJA'), findsOneWidget);
    expect(find.byType(SvgPicture), findsWidgets);
  });

  testWidgets('PlanDetailSheet muestra condiciones y CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: totoTheme(),
        home: Scaffold(
          body: PlanDetailSheet(
            plan: samplePlans[1],
            onChoose: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('LA FIJA'), findsOneWidget);
    expect(find.text('QUÉ LLEVAS CON TU PLAN'), findsOneWidget);
    expect(find.text('ELEGIR LA FIJA'), findsOneWidget);
  });
}
