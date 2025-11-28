# Verifier Quick Reference Card

**Role**: Third-party verification of sprint task completion  
**Time Budget**: 10-15 minutes per task  
**Authority**: REJECT any task that fails checks

> **For automated/triggered verification**: See [automated-verification-workflow.md](./automated-verification-workflow.md)
> **For screenshot verification**: See [screenshot-verification.md](./screenshot-verification.md)

---

## 🚨 INSTANT REJECTION (Stop Immediately)

| Finding | Action |
|---------|--------|
| Missing verification artifacts | ❌ REJECT |
| `expect(find.byType(X), findsOneWidget)` as ONLY assertion | ❌ REJECT |
| "Integration" task with only NEW files in diff | ❌ REJECT |
| Screenshot shows feature NOT working | ❌ REJECT |
| Git diff shows only test file changes | ❌ REJECT |
| "TODO: implement" in committed code | ❌ REJECT |
| New function/class with zero callers | ❌ REJECT |
| Screenshot naming doesn't match `T###_testname_##_desc.png` | ❌ REJECT |
| Screenshot manifest in test file doesn't match actual files | ❌ REJECT |

---

## ✅ Verification Steps (10 min)

### Step 1: Artifacts (1 min)
```
docs/verification/T###/
├── README.md        ← Required
├── git_diff.txt     ← Required  
├── test_output.txt  ← Required
├── screenshot.png   ← If UI task
└── checklist.md     ← Required
```
**Missing any? → REJECT**

### Step 2: Git Diff (2 min)
```bash
cat docs/verification/T###/git_diff.txt | head -20
```
Check:
- [ ] Expected files appear
- [ ] For INTEGRATION: 2+ files modified
- [ ] Actual code changes (not just comments)

### Step 3: Test Quality (3 min)
```bash
grep -n "expect(" path/to/test.dart
```
**🚨 Red Flags:**
- `findsOneWidget` alone
- `isNotNull` alone
- `isTrue` without context
- Comments like "// TODO: add real assertion"

### Step 4: Run Tests (2 min)
```bash
flutter test path/to/test.dart
```
- [ ] All pass
- [ ] Matches test_output.txt

### Step 5: Visual Check (2 min)
- Open `screenshot.png` OR check `example/screenshots/T###_*.png`
- Verify screenshot naming: `{TaskID}_{TestName}_{Step}_{Description}.png`
- Does it show the feature WORKING?
- For multi-axis: Do you see MULTIPLE axes?
- Check test file for `/// SCREENSHOT MANIFEST for Task T###`
- All listed screenshots must exist

### Step 6: Screenshot Manifest Check (1 min)
```powershell
# Check manifest in test file
Select-String -Path "example/integration_test/*T###*.dart" -Pattern "SCREENSHOT MANIFEST" -Context 0,10

# Verify screenshots exist
Get-ChildItem "example/screenshots/T###_*.png"
```
- [ ] Manifest exists in test file
- [ ] All manifested screenshots exist
- [ ] Screenshots show feature working

---

## 📋 Verdict Template

```markdown
## Task T### Verification

**Verifier**: [Name/Agent ID]
**Date**: [YYYY-MM-DD]
**Commit**: [SHA]

### Checks
- [ ] Artifacts present
- [ ] Git diff valid (type-appropriate)
- [ ] Tests meaningful (not just findsOneWidget)
- [ ] Tests pass
- [ ] Screenshot manifest matches files
- [ ] Visual verified (feature works)

### Verdict: [APPROVED/REJECTED/NEEDS WORK]

**Notes**: 

### For REJECTED - Specific Reasons:
1. 
2. 
```

---

## 🔍 Test Assertion Cheat Sheet

### ❌ WORTHLESS (Reject)
```dart
expect(find.byType(Widget), findsOneWidget);
expect(result, isNotNull);
expect(list.isEmpty, isFalse);
```

### ✅ MEANINGFUL (Accept)
```dart
expect(find.text('Power (W)'), findsOneWidget);
expect(result.value, equals(42));
expect(list.length, equals(3));
expect(leftAxis.right, lessThan(plotArea.left));
await expectLater(find.byType(X), matchesGoldenFile('x.png'));
```

---

## 🎯 Key Questions

For every task ask:

1. **"Would this test FAIL if the feature was broken?"**
   - If No → Tests are worthless

2. **"Does the git diff show EXISTING files changed?"**
   - For MODIFY/INTEGRATE tasks, must be Yes

3. **"Can I SEE the feature working in the screenshot?"**
   - If not visible → Not proven

4. **"Is new code actually CALLED from somewhere?"**
   - Dead code = incomplete task

---

## 📞 Escalation

If you find:
- Multiple tasks with same issues
- Pattern of weak tests
- Systemic skipping of verification

→ **STOP verification, escalate to project lead**

---

*"Trust nothing. Verify everything. Reject liberally."*
