# Native Windows export, executable metadata, portable ZIP and Inno Setup installer.
param([ValidateSet('all', 'toolchain', 'export', 'installer', 'validate')][string] $Phase = 'all')
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$tools = Join-Path $root '.tools'
$export = Join-Path $root 'builds/windows-release'
$output = Join-Path $root 'builds/releases'
$logs = Join-Path $root 'builds/windows-validation'
New-Item -ItemType Directory -Force $tools, $export, $output, $logs | Out-Null
$script:engine = Join-Path $tools 'Godot_v4.3-stable_win64_console.exe'
$script:commandNumber = 0
$exe = Join-Path $export 'RoadShift.exe'
$setup = Join-Path $output 'RoadShift-Setup-Windows-x64.exe'
$compiler = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
$versionMatch = [regex]::Match((Get-Content "$root/project.godot" -Raw), '(?m)^config/version="([^"]+)"')
$version = $versionMatch.Groups[1].Value
$work = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
$env:PATH = "$tools;$env:PATH"

function Download-Checked($url, $path, $hash, $algorithm) {
    Write-Host "Downloading/verifying $(Split-Path $path -Leaf)"
    if (!(Test-Path $path)) {
        $partial = "$path.part"
        & curl.exe --fail --location --retry 2 --continue-at - --connect-timeout 30 --max-time 300 --speed-time 60 --speed-limit 1024 --silent --show-error $url --output $partial
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $url" }
        if ((Get-FileHash $partial -Algorithm $algorithm).Hash.ToLowerInvariant() -ne $hash) { throw "Checksum mismatch: $partial" }
        Move-Item $partial $path
    }
    if ((Get-FileHash $path -Algorithm $algorithm).Hash.ToLowerInvariant() -ne $hash) {
        throw "Checksum mismatch: $path"
    }
}
function Godot-Checked([string[]] $arguments) {
    Write-Host "Godot: $($arguments -join ' ')"
    $script:commandNumber++
    $stdout = Join-Path $logs "$Phase-$script:commandNumber.stdout.log"
    $stderr = Join-Path $logs "$Phase-$script:commandNumber.stderr.log"
    $quoted = ($arguments | ForEach-Object { '"' + $_.Replace('"', '\"') + '"' }) -join ' '
    $process = Start-Process $script:engine -ArgumentList $quoted -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    if (!$process.WaitForExit(120000)) { $process.Kill(); throw 'Godot command exceeded two minutes' }
    $process.WaitForExit()
    $text = Get-Content $stdout -Raw
    $errors = Get-Content $stderr -Raw
    Write-Output $text
    if ($errors) { Write-Output $errors }
    if ($process.ExitCode -ne 0 -or $errors -match 'SCRIPT ERROR:|ERROR:|Parse Error') { throw 'Godot command failed; see validation logs' }
    if ($arguments -contains '--version' -and $text.Trim() -ne '4.3.stable.official.77dcf97d8') { throw 'Wrong Godot version' }
}

if ($Phase -in @('all', 'toolchain')) {
$baseUrl = 'https://github.com/godotengine/godot-builds/releases/download/4.3-stable'
$editorZip = Join-Path $tools 'Godot_v4.3-stable_win64.exe.zip'
Download-Checked "$baseUrl/Godot_v4.3-stable_win64.exe.zip" $editorZip 'ad09b7e19949327700dfbe64e35880a2a08091c0751277f5cc21b915e5df9b4fe93fb43c50d6bdfb9d16b46168592491aa698e0d2dbe9f92132e163dd77b97e1' 'SHA512'
Expand-Archive $editorZip -DestinationPath $tools -Force
Godot-Checked @('--version')
python "$root/tools/install_export_templates.py" --platform windows
if ($LASTEXITCODE -ne 0) { throw 'Template installation failed' }

$rcedit = Join-Path $tools 'rcedit.exe'
Download-Checked 'https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe' $rcedit '3e7801db1a5edbec91b49a24a094aad776cb4515488ea5a4ca2289c400eade2a' 'SHA256'
}
if ($Phase -in @('all', 'export')) {
Godot-Checked @('--headless', '--editor', '--path', $root, '--import', '--quit')
Godot-Checked @('--headless', '--path', $root, '--export-release', 'Windows x64', $exe)
$metadata = (Get-Item $exe).VersionInfo
if ($metadata.ProductName -ne 'RoadShift' -or $metadata.FileVersion -ne "$version.0") {
    throw 'Windows executable product/version stamping failed'
}
Godot-Checked @('--headless', '--path', $root, '--script', 'res://tools/make_windows_icon.gd')
python "$root/tools/package_desktop.py" windows
if ($LASTEXITCODE -ne 0) { throw 'Portable package validation failed' }
}

if ($Phase -in @('all', 'installer')) {
if (!(Test-Path $compiler)) {
    choco install innosetup --version=6.4.3 --yes --no-progress
    if ($LASTEXITCODE -ne 0) { throw 'Inno Setup installation failed' }
}
& $compiler "/DAppVersion=$version" "/DExportDir=$export" "/DOutputDir=$output" "/DIconFile=$root/builds/branding/icon.ico" "$root/packaging/windows.iss" | Tee-Object -Variable compilerOutput
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
$compilerVersion = [regex]::Match(($compilerOutput -join "`n"), 'Compiler engine version: Inno Setup ([0-9.]+)').Groups[1].Value
if (!$compilerVersion) { throw 'Could not determine the actual installer compiler version' }
Set-Content (Join-Path $logs 'compiler-version.txt') $compilerVersion -NoNewline -Encoding utf8
if (!(Test-Path $setup) -or (Get-Item $setup).Length -lt 1MB) { throw 'Missing/invalid installer' }
}

if ($Phase -in @('all', 'validate')) {
# Actual Windows headless runtime test, from outside the source tree.
function Smoke-Test($runtime, $label) {
    $log = Join-Path $work "$label.log"
    $process = Start-Process -FilePath $runtime -WorkingDirectory $work -ArgumentList "--headless --quit-after 120 --log-file `"$log`" -- --sandbox --quickstart" -PassThru
    if (!$process.WaitForExit(60000)) { $process.Kill(); throw "$label timed out" }
    if ($process.ExitCode -ne 0) { throw "$label exited $($process.ExitCode)" }
    if (!(Test-Path $log)) { throw "$label did not write its startup log" }
    $text = Get-Content $log -Raw
    if ($text -match 'SCRIPT ERROR:|ERROR:|Parse Error|Failed to load') { throw "$label runtime errors: $text" }
    Write-Output "PASSED: $label Windows headless startup"
}
Smoke-Test $exe 'portable'

# Install/shortcut/reinstall/uninstall checks use only this disposable CI runner.
$install = Join-Path $work 'RoadShift installer test'
function Install-Test {
    $process = Start-Process $setup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR=`"$install`"" -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Installer exited $($process.ExitCode)" }
}
Install-Test
$installedExe = Join-Path $install 'RoadShift.exe'
if (!(Test-Path $installedExe) -or !(Test-Path "$install/RoadShift.pck")) { throw 'Installer omitted runtime/data' }
$shortcut = Join-Path ([Environment]::GetFolderPath('Programs')) 'RoadShift/RoadShift.lnk'
if (!(Test-Path $shortcut)) { throw 'Start Menu shortcut missing' }
Smoke-Test $installedExe 'installed'
$saveDir = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'godot/app_userdata/Harborline Dispatch'
New-Item -ItemType Directory -Force $saveDir | Out-Null
$saveMarker = Join-Path $saveDir 'installer-save-preservation.txt'
Set-Content $saveMarker 'keep progress outside the installation'
Install-Test
if (!(Test-Path $saveMarker)) { throw 'Reinstallation deleted user data' }
$uninstall = Start-Process "$install/unins000.exe" -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait -PassThru
if ($uninstall.ExitCode -ne 0 -or (Test-Path $installedExe) -or (Test-Path $shortcut) -or !(Test-Path $saveMarker)) {
    throw 'Uninstall or save preservation failed'
}
$report = @(
    "RoadShift v$version",
    "Source: $(git -C $root rev-parse HEAD)",
    'Godot: 4.3.stable.official.77dcf97d8; official SHA-512 verified release templates',
    "Installer compiler: Inno Setup $((Get-Content (Join-Path $logs 'compiler-version.txt') -Raw).Trim())",
    'PASSED: x64 PE32+ executable, Godot 4.3 PCK, portable ZIP CRC/structure',
    'PASSED: product name, version metadata and existing project icon',
    'PASSED: portable and installed Windows headless startup',
    'PASSED: silent installation, Start Menu shortcut, reinstallation, uninstall and user-data preservation',
    'NOT TESTED: Windows graphical rendering, interactive gameplay and subjective audio'
)
Set-Content (Join-Path $output 'Windows-validation.txt') (($report -join "`n") + "`n") -NoNewline -Encoding utf8
$checksums = @((Join-Path $output 'RoadShift-Windows-x64.zip'), $setup) | Get-Item | ForEach-Object {
    "$((Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())  $($_.Name)"
}
Set-Content (Join-Path $output 'SHA256SUMS-Windows.txt') (($checksums -join "`n") + "`n") -NoNewline -Encoding utf8
$report | Write-Output
}
