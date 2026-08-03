param(
  [ValidateRange(1, 10)]
  [int]$Repeat = 3,

  [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$targets = @(
  'test/benchmarks/rendering/heatmap_series_element_benchmark_test.dart',
  'test/benchmarks/interaction/persistent_selection_brush_benchmark_test.dart',
  'test/benchmarks/interaction/chart_selection_expression_benchmark_test.dart',
  'test/benchmarks/models/heatmap_histogram_data_benchmark_test.dart',
  'test/benchmarks/models/heatmap_density_data_benchmark_test.dart',
  'test/benchmarks/models/heatmap_contour_data_benchmark_test.dart',
  'test/benchmarks/models/heatmap_cluster_data_benchmark_test.dart',
  'test/benchmarks/widgets/heatmap_dendrogram_benchmark_test.dart',
  'test/benchmarks/controllers/heatmap_viewport_controller_benchmark_test.dart',
  'test/benchmarks/controllers/heatmap_raster_viewport_controller_benchmark_test.dart'
)

$transcript = [System.Collections.Generic.List[string]]::new()

Push-Location $repositoryRoot
try {
  for ($pass = 1; $pass -le $Repeat; $pass++) {
    $passHeader = "===== Heatmap performance audit pass $pass/$Repeat ====="
    Write-Output $passHeader
    $transcript.Add($passHeader)

    foreach ($target in $targets) {
      $targetHeader = "===== $target ====="
      Write-Output $targetHeader
      $transcript.Add($targetHeader)

      $output = & flutter test $target --reporter expanded --concurrency=1 2>&1
      $exitCode = $LASTEXITCODE
      $output | ForEach-Object {
        $line = $_.ToString()
        Write-Output $line
        $transcript.Add($line)
      }

      if ($exitCode -ne 0) {
        throw "Heatmap performance audit failed for $target (exit $exitCode)."
      }
    }
  }
}
finally {
  Pop-Location
}

if ($OutputPath) {
  $resolvedOutput = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
  } else {
    Join-Path $repositoryRoot $OutputPath
  }
  $outputDirectory = Split-Path -Parent $resolvedOutput
  if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
  }
  [System.IO.File]::WriteAllLines($resolvedOutput, $transcript)
  Write-Output "Heatmap audit transcript: $resolvedOutput"
}
