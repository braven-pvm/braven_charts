# Verification Check Script
# Automatically detects anti-patterns and integration failures
#
# Usage: .\verification_check.ps1 [-Full] [-LastCommit] [-Verbose]
#
# Created as part of the verification framework after the
# 011-multi-axis-normalization sprint failure.

param(
    [switch]$Full,           # Run all checks (slower)
    [switch]$LastCommit,     # Check only last commit changes
    [switch]$Verbose,        # Show detailed output
    [string]$Path = "."      # Path to check (default: current directory)
)

$ErrorActionPreference = "Continue"
$WarningColor = "Yellow"
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"

# ============================================================================
# HEADER
# ============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $InfoColor
Write-Host "║           ANTI-PATTERN DETECTION & VERIFICATION CHECK          ║" -ForegroundColor $InfoColor
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor $InfoColor
Write-Host ""

$failures = 0
$warnings = 0
$checks = 0

function Write-Check {
    param($Name)
    $script:checks++
    Write-Host "  ▶ $Name" -ForegroundColor White -NoNewline
}

function Write-Pass {
    Write-Host " ✓ PASS" -ForegroundColor $SuccessColor
}

function Write-Warn {
    param($Message)
    $script:warnings++
    Write-Host " ⚠ WARNING" -ForegroundColor $WarningColor
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor $WarningColor
    }
}

function Write-Fail {
    param($Message)
    $script:failures++
    Write-Host " ✗ FAIL" -ForegroundColor $ErrorColor
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor $ErrorColor
    }
}

# ============================================================================
# CHECK 1: ORPHAN CLASSES (AP-I01)
# Find classes that are defined but never imported/used elsewhere
# ============================================================================

Write-Host "═══ CHECKING FOR ORPHAN CLASSES (AP-I01) ═══" -ForegroundColor $InfoColor
Write-Host ""

$libFiles = Get-ChildItem -Path "$Path/lib" -Recurse -Filter "*.dart" -ErrorAction SilentlyContinue

if ($libFiles) {
    foreach ($file in $libFiles) {
        # Extract class names from file
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match "class\s+(\w+)") {
            $className = $Matches[1]
            
            # Count how many files reference this class
            $usageCount = (Get-ChildItem -Path "$Path/lib" -Recurse -Filter "*.dart" | 
                ForEach-Object { 
                    $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                    if ($c -match $className -and $_.FullName -ne $file.FullName) { 1 } else { 0 }
                } | Measure-Object -Sum).Sum

            if ($usageCount -eq 0) {
                Write-Check "Class $className in $($file.Name)"
                Write-Warn "Class is defined but never used elsewhere"
            }
        }
    }
}

# ============================================================================
# CHECK 2: WIDGET EXISTENCE TESTS (AP-T01)
# Find tests that only check findsOneWidget
# ============================================================================

Write-Host ""
Write-Host "═══ CHECKING FOR WEAK TESTS (AP-T01) ═══" -ForegroundColor $InfoColor
Write-Host ""

$testFiles = Get-ChildItem -Path "$Path/test" -Recurse -Filter "*_test.dart" -ErrorAction SilentlyContinue

foreach ($file in $testFiles) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        # Count expect statements
        $expectCount = ([regex]::Matches($content, "expect\(")).Count
        
        # Count findsOneWidget specifically
        $findsOneWidgetCount = ([regex]::Matches($content, "findsOneWidget")).Count
        
        # Check if the only assertions are findsOneWidget
        if ($expectCount -gt 0 -and $findsOneWidgetCount -eq $expectCount) {
            Write-Check "$($file.Name)"
            Write-Fail "Only uses findsOneWidget assertions - tests nothing meaningful"
        } elseif ($expectCount -eq 0) {
            Write-Check "$($file.Name)"
            Write-Fail "No expect() statements found - test proves nothing"
        } elseif ($findsOneWidgetCount -gt ($expectCount / 2)) {
            Write-Check "$($file.Name)"
            Write-Warn "$findsOneWidgetCount/$expectCount assertions are just findsOneWidget"
        }
    }
}

# ============================================================================
# CHECK 3: INTEGRATION VERIFICATION (AP-I02)
# For recent commits, verify integration tasks actually modify target files
# ============================================================================

Write-Host ""
Write-Host "═══ CHECKING LAST COMMIT INTEGRATION (AP-I02) ═══" -ForegroundColor $InfoColor
Write-Host ""

try {
    $commitMessage = git log -1 --pretty=%B 2>$null
    if ($commitMessage -match "integrate|integration|connect|wire|hook") {
        Write-Check "Last commit mentions integration"
        
        $changedFiles = git diff --name-only HEAD~1 2>$null
        $hasNewFiles = $changedFiles | Where-Object { $_ -match "lib/" }
        $hasModifiedCore = $changedFiles | Where-Object { 
            $_ -match "render_box|painter|widget.*\.dart" -and 
            (git diff HEAD~1 -- $_ 2>$null) -match "^\+" 
        }
        
        if ($hasNewFiles -and -not $hasModifiedCore) {
            Write-Fail "Integration commit only added new files, didn't modify core files"
        } else {
            Write-Pass
        }
    } else {
        Write-Host "  (Last commit is not an integration task)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  (Git not available or not in repo)" -ForegroundColor Gray
}

# ============================================================================
# CHECK 4: RENDER METHOD CONNECTIVITY (AP-I04)
# Verify that new renderers are actually called from paint()
# ============================================================================

Write-Host ""
Write-Host "═══ CHECKING RENDER METHOD CONNECTIVITY (AP-I04) ═══" -ForegroundColor $InfoColor
Write-Host ""

$renderBoxFile = Get-ChildItem -Path "$Path/lib" -Recurse -Filter "*render_box*.dart" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($renderBoxFile) {
    $renderContent = Get-Content $renderBoxFile.FullName -Raw -ErrorAction SilentlyContinue
    
    # Find renderer files
    $rendererFiles = Get-ChildItem -Path "$Path/lib" -Recurse -Filter "*renderer*.dart" -ErrorAction SilentlyContinue
    
    foreach ($renderer in $rendererFiles) {
        if ($renderer.Name -ne $renderBoxFile.Name) {
            $rendererContent = Get-Content $renderer.FullName -Raw -ErrorAction SilentlyContinue
            if ($rendererContent -match "class\s+(\w+Renderer)") {
                $rendererClass = $Matches[1]
                
                Write-Check "Renderer $rendererClass"
                
                if ($renderContent -match $rendererClass) {
                    Write-Pass
                } else {
                    Write-Warn "Not found in paint() method - may be orphaned"
                }
            }
        }
    }
}

# ============================================================================
# CHECK 5: WIDGET-RENDEROBJECT PARAMETER FLOW (AP-I03)
# Verify widget parameters are passed to render object
# ============================================================================

Write-Host ""
Write-Host "═══ CHECKING WIDGET-RENDEROBJECT PARAMETER FLOW (AP-I03) ═══" -ForegroundColor $InfoColor
Write-Host ""

$widgetFiles = Get-ChildItem -Path "$Path/lib" -Recurse -Filter "*widget*.dart" -ErrorAction SilentlyContinue

foreach ($widgetFile in $widgetFiles) {
    $content = Get-Content $widgetFile.FullName -Raw -ErrorAction SilentlyContinue
    if ($content) {
        # Find widget parameters that look like configurations
        $configParams = [regex]::Matches($content, "final\s+List<\w+Config>\s+(\w+);")
        
        foreach ($match in $configParams) {
            $paramName = $match.Groups[1].Value
            Write-Check "Parameter $paramName in $($widgetFile.Name)"
            
            # Check if there's a corresponding setter call
            if ($content -match "set$paramName|\.${paramName}\s*=" ) {
                Write-Pass
            } else {
                Write-Warn "No setter found - parameter may not reach RenderObject"
            }
        }
    }
}

# ============================================================================
# CHECK 6: GOLDEN TESTS FOR VISUAL FEATURES (AP-T04)
# Verify visual features have golden tests
# ============================================================================

Write-Host ""
Write-Host "═══ CHECKING FOR GOLDEN TESTS (AP-T04) ═══" -ForegroundColor $InfoColor
Write-Host ""

$goldenCount = (Get-ChildItem -Path "$Path/test" -Recurse -Filter "*.png" -ErrorAction SilentlyContinue).Count
$chartTestFiles = Get-ChildItem -Path "$Path/test" -Recurse -Filter "*chart*_test.dart" -ErrorAction SilentlyContinue

Write-Check "Golden test files exist"
if ($goldenCount -gt 0) {
    Write-Pass
    Write-Host "    Found $goldenCount golden files" -ForegroundColor Gray
} else {
    Write-Warn "No golden test files found for visual verification"
}

foreach ($testFile in $chartTestFiles) {
    $content = Get-Content $testFile.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and -not ($content -match "matchesGoldenFile")) {
        Write-Check "$($testFile.Name)"
        Write-Warn "Chart test without golden tests - Canvas content not verified"
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor $InfoColor
Write-Host "║                           SUMMARY                              ║" -ForegroundColor $InfoColor
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor $InfoColor
Write-Host ""

Write-Host "  Checks Run:  $checks" -ForegroundColor White
Write-Host "  Failures:    $failures" -ForegroundColor $(if ($failures -gt 0) { $ErrorColor } else { $SuccessColor })
Write-Host "  Warnings:    $warnings" -ForegroundColor $(if ($warnings -gt 0) { $WarningColor } else { $SuccessColor })
Write-Host ""

if ($failures -gt 0) {
    Write-Host "  ❌ VERIFICATION FAILED - Address failures before proceeding" -ForegroundColor $ErrorColor
    exit 1
} elseif ($warnings -gt 0) {
    Write-Host "  ⚠️  VERIFICATION PASSED WITH WARNINGS - Review warnings" -ForegroundColor $WarningColor
    exit 0
} else {
    Write-Host "  ✅ VERIFICATION PASSED - All checks clear" -ForegroundColor $SuccessColor
    exit 0
}
