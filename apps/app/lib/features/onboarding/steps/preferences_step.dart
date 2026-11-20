import 'package:app/features/onboarding/onboarding_step.dart';
import 'package:app/features/onboarding/steps/onboarding_saved_hint.dart';
import 'package:app/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:mix/mix.dart';
import 'package:naked_ui/naked_ui.dart';
import 'package:ui/ui.dart';

/// The template's default second step: a single-choice "how will you use
/// this" question. The whole step's answer is the chosen option's id (a
/// plain `String`). "Personal use" is the [OnboardingStep.defaultAnswer],
/// so it reads as saved on arrival, as the mockup shows.
OnboardingStep preferencesOnboardingStep() {
  return OnboardingStep(
    id: 'preferences',
    title: t.onboarding.stepPreferencesTitle,
    skip: OnboardingSkipAffordance.topLink,
    defaultAnswer: _personalOptionId,
    builder: (_, scope) => _PreferencesStepBody(scope: scope),
  );
}

const String _personalOptionId = 'personal';
const String _workOptionId = 'work';
const String _exploringOptionId = 'exploring';

// This file is named for the step it defines; the top-level
// `preferencesOnboardingStep()` factory (not a class) is this file's real
// public surface, so its first class — a private body widget — doesn't
// literally match the file name. Same convention as
// `core/design/ui/lib/src/components/*.dart`.
// ignore: solid_lints/prefer_match_file_name
class _PreferencesStepBody extends StatelessWidget {
  const _PreferencesStepBody({required this.scope});

  final OnboardingStepScope scope;

  @override
  Widget build(BuildContext context) {
    final selected = scope.answer as String? ?? _personalOptionId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StyledText(
          t.onboarding.stepPreferencesQuestion(appName: t.appTitle),
          style: bodyStyle(),
        ),
        const AppGap.v4(),
        NakedRadioGroup<String>(
          groupValue: selected,
          semanticLabel: t.onboarding.stepPreferencesTitle,
          onChanged: (value) {
            if (value != null) scope.onChanged(value);
          },
          child: const _PreferenceOptionList(),
        ),
        const AppGap.v4(),
        OnboardingSavedHint(visible: scope.answer != null),
      ],
    );
  }
}

class _PreferenceOptionList extends StatelessWidget {
  const _PreferenceOptionList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreferenceOption(
          value: _personalOptionId,
          title: t.onboarding.stepPreferencesOptionPersonalTitle,
          hint: t.onboarding.stepPreferencesOptionPersonalHint,
        ),
        const AppGap.v3(),
        _PreferenceOption(
          value: _workOptionId,
          title: t.onboarding.stepPreferencesOptionWorkTitle,
          hint: t.onboarding.stepPreferencesOptionWorkHint,
        ),
        const AppGap.v3(),
        _PreferenceOption(
          value: _exploringOptionId,
          title: t.onboarding.stepPreferencesOptionExploringTitle,
          hint: t.onboarding.stepPreferencesOptionExploringHint,
        ),
      ],
    );
  }
}

class _PreferenceOption extends StatelessWidget {
  const _PreferenceOption({
    required this.value,
    required this.title,
    required this.hint,
  });

  final String value;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return NakedRadio<String>(
      value: value,
      semanticLabel: '$title. $hint',
      builder: (_, state, _) => _PreferenceOptionRow(
        title: title,
        hint: hint,
        selected: state.states.contains(WidgetState.selected),
      ),
    );
  }
}

/// The row's visual chrome: a bordered box (highlighted when [selected]), a
/// circular radio glyph, and a title/hint pair — mirrors the mockups'
/// `.radio-row`.
class _PreferenceOptionRow extends StatelessWidget {
  const _PreferenceOptionRow({
    required this.title,
    required this.hint,
    required this.selected,
  });

  final String title;
  final String hint;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Box(
      // No token matches the mockup's 56px row min-height exactly
      // (space12=48, space16=64, equidistant) — kept the nearest, space12.
      style: BoxStyler()
          .minHeight(space12())
          .paddingX(space4())
          .borderAll(
            color: selected ? colorAccent() : colorBorder(),
            width: strokeThin(),
          ),
      child: Row(
        children: [
          _RadioGlyph(selected: selected),
          const AppGap.h3(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StyledText(title, style: bodyStyle()),
                StyledText(hint, style: captionStyle()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioGlyph extends StatelessWidget {
  const _RadioGlyph({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Box(
      // No token matches the mockup's 20px glyph exactly (space4=16,
      // space6=24, equidistant) — kept the nearest, space4.
      style: BoxStyler()
          .size(space4(), space4())
          .borderAll(
            color: selected ? colorAccent() : colorBorder(),
            width: strokeStrong(),
          ),
      child: selected
          ? Center(
              child: Box(
                // No token matches the mockup's 10px dot exactly
                // (space2=8, space3=12, equidistant) — kept space2.
                style: BoxStyler()
                    .size(space2(), space2())
                    .color(colorAccent()),
              ),
            )
          : null,
    );
  }
}
