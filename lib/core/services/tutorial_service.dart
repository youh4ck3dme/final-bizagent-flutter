import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialService {
  static void showDashboardTutorial({
    required BuildContext context,
    required GlobalKey dashboardKey,
    required GlobalKey scanKey,
    required GlobalKey invoiceKey,
    required VoidCallback onFinish,
  }) {
    List<TargetFocus> targets = [];

    // 1. Dashboard Checklist (Smart Empty State)
    targets.add(
      TargetFocus(
        identify: "dashboard_empty_state",
        keyTarget: dashboardKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tu začnite svoje podnikanie",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Tento zoznam vás prevedie nastavením firmy a prvými krokmi.",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
    );

    // 2. Scan Receipt
    targets.add(
      TargetFocus(
        identify: "scan_receipt",
        keyTarget: scanKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Umelá Inteligencia",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Odfotťe bloček a AI automaticky vyčíta všetky údaje. Žiadne prepisovanie!",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
    );

    // 3. Create Invoice
    targets.add(
      TargetFocus(
        identify: "create_invoice",
        keyTarget: invoiceKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Faktúra do 30 sekúnd",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Vytvorte profesionálnu faktúru s QR kódom pre klienta.",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        shape: ShapeLightFocus.RRect,
        radius: 12,
      ),
    );

    TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF2563EB), // Premium Blue opacity handled by package
      textSkip: "PRESKOČIŤ",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: onFinish,
      onSkip: () {
        onFinish();
        return true;
      },
      onClickTarget: (target) {
         // Continue to next tool
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        // Continue
      },
      onClickOverlay: (target) {
        // Continue
      },
    ).show(context: context);
  }
}
