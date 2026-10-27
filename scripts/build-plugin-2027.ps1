param(
  [string]$AutoCADRoot = "C:\Program Files\Autodesk\AutoCAD 2027",
  [string]$Configuration = "Release",
  [string]$TargetFramework = "net10.0-windows"
)

# Compila o Civil3DMcpPlugin.dll para o Civil 3D 2027 (.NET 10).
# 1) Localiza as 6 DLLs gerenciadas da Autodesk na instalacao local
# 2) Copia para C_References\ (pasta ignorada pelo git; nada da Autodesk e versionado)
# 3) Roda dotnet build apontando para essa pasta

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$pluginProject = Join-Path $repoRoot "Civil3D-MCP-Plugin\Civil3DMcpPlugin.csproj"
$refsDir = Join-Path $repoRoot "C_References"
$required = @(
  "accoremgd.dll",
  "AcDbMgd.dll",
  "acmgd.dll",
  "AecBaseMgd.dll",
  "AeccDbMgd.dll",
  "AeccPressurePipesMgd.dll"
)

if (-not (Test-Path $AutoCADRoot)) {
  throw "Pasta do Civil 3D nao encontrada: '$AutoCADRoot'. Use -AutoCADRoot para informar o caminho correto."
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
  throw "dotnet nao encontrado no PATH. Instale o .NET SDK 10."
}

$sdks = & dotnet --list-sdks
if (-not ($sdks | Where-Object { $_ -match '^10\.' })) {
  throw ".NET SDK 10 nao encontrado. SDKs instalados:`n$($sdks -join "`n")"
}

New-Item -ItemType Directory -Force -Path $refsDir | Out-Null

foreach ($dll in $required) {
  # Preferir a raiz do AutoCAD; se nao estiver la, procurar nas subpastas (ex.: C3D, ACA)
  $candidate = Join-Path $AutoCADRoot $dll
  if (-not (Test-Path $candidate)) {
    $found = Get-ChildItem -Path $AutoCADRoot -Filter $dll -Recurse -ErrorAction SilentlyContinue |
      Sort-Object { $_.FullName.Length } | Select-Object -First 1
    if (-not $found) {
      throw "Nao encontrei '$dll' dentro de '$AutoCADRoot'."
    }
    $candidate = $found.FullName
  }
  Copy-Item -Path $candidate -Destination (Join-Path $refsDir $dll) -Force
  Write-Host "  ok  $dll  <-  $candidate"
}

Write-Host "`nCompilando plugin ($TargetFramework, $Configuration)..."
& dotnet build $pluginProject -c $Configuration `
  "/p:Civil3DReferencesPath=$refsDir" `
  "/p:Civil3DTargetFramework=$TargetFramework"
if ($LASTEXITCODE -ne 0) {
  throw "Falha na compilacao do plugin. Copie os erros e envie para analise."
}

$dllOut = Join-Path $repoRoot "Civil3D-MCP-Plugin\bin\$Configuration\$TargetFramework\Civil3DMcpPlugin.dll"
Write-Host "`nPlugin gerado em:`n  $dllOut"
Write-Host "No Civil 3D 2027: NETLOAD -> selecione esse arquivo -> depois rode C3DMCPSTATUS."
