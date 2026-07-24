import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _registerRoot = r'F:\Repositories\_braven_charts_register';
const _listCommand =
    r"& 'F:\Repositories\_braven_charts_register\register.ps1' list";

String _read(String path) => File(path).readAsStringSync();

void main() {
  test('all agent discovery surfaces name the canonical shared register', () {
    final agentInstructions = _read('AGENTS.md');
    final copilotInstructions = _read('.github/copilot-instructions.md');
    final onboarding = _read('docs/agent_onboarding.md');
    final issueWorkflow = _read('docs/issue_workflow.md');

    for (final entry in <String, String>{
      'AGENTS.md': agentInstructions,
      '.github/copilot-instructions.md': copilotInstructions,
      'docs/agent_onboarding.md': onboarding,
      'docs/issue_workflow.md': issueWorkflow,
    }.entries) {
      expect(
        entry.value,
        contains(_registerRoot),
        reason: '${entry.key} must name the one branch-independent register.',
      );
      expect(
        entry.value,
        contains(_listCommand),
        reason: '${entry.key} must provide the exact discovery command.',
      );
      expect(
        entry.value,
        contains('Shared register sync pending'),
        reason:
            '${entry.key} must define the external-host fallback explicitly.',
      );
    }
  });

  test('guidance separates tracking state from implementation evidence', () {
    final agentInstructions = _read('AGENTS.md');
    final copilotInstructions = _read('.github/copilot-instructions.md');
    final onboarding = _read('docs/agent_onboarding.md');
    final issueWorkflow = _read('docs/issue_workflow.md');

    expect(agentInstructions, contains('not proof'));
    expect(copilotInstructions, contains('not implementation proof'));
    expect(onboarding, contains('not implementation proof'));
    expect(issueWorkflow, contains('GitHub remains the execution contract'));
    expect(
      issueWorkflow,
      contains('current implementation/CI evidence'),
      reason: 'Drift reconciliation must prefer verified delivery evidence.',
    );
  });

  test('contributor and PR guidance preserve the register handoff', () {
    final contributing = _read('CONTRIBUTING.md');
    final pullRequestTemplate = _read('.github/pull_request_template.md');

    expect(contributing, contains('[AGENTS.md](AGENTS.md)'));
    expect(
      contributing,
      contains('External contributors are not expected to have access'),
    );
    expect(pullRequestTemplate, contains('Register item: BC-####'));
    expect(pullRequestTemplate, contains('synchronized back to the register'));
  });

  test('every custom GitHub agent bootstraps through root AGENTS.md', () {
    final agentFiles =
        Directory('.github/agents')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.agent.md'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));

    expect(agentFiles, isNotEmpty);
    for (final file in agentFiles) {
      final contents = file.readAsStringSync();
      expect(
        contents,
        contains('root `AGENTS.md`'),
        reason: '${file.path} must enter through the canonical agent guidance.',
      );
      expect(
        contents,
        contains('Shared register sync pending'),
        reason: '${file.path} must retain the external-host fallback.',
      );
      expect(
        contents,
        contains('GitHub'),
        reason: '${file.path} must prefer live delivery evidence when offline.',
      );
    }
  });

  test('every repository-owned Claude skill bootstraps through AGENTS.md', () {
    final skillFiles =
        Directory('.claude/skills')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('SKILL.md'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));

    expect(skillFiles, isNotEmpty);
    for (final file in skillFiles) {
      final contents = file.readAsStringSync();
      expect(
        contents,
        contains('root `AGENTS.md`'),
        reason: '${file.path} must enter through the canonical agent guidance.',
      );
      expect(
        contents,
        contains('Shared register sync pending'),
        reason: '${file.path} must retain the external-host fallback.',
      );
      expect(
        contents,
        contains('GitHub'),
        reason: '${file.path} must prefer live delivery evidence when offline.',
      );
    }
  });

  test('the external register is not vendored into this repository', () {
    expect(
      Directory('_braven_charts_register').existsSync(),
      isFalse,
      reason:
          'The live register must remain outside Git and shared by all lanes.',
    );
  });
}
