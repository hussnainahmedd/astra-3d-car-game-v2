# Native Windows export, executable metadata, portable ZIP and Inno Setup installer.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$tools = Join-Path $root '.tools'
$export = Join-Path $root 'builds/windows-release'
$output = Join-Path $root 'builds/releases'
New-Item -ItemType Directory -Force $tools, $export, $output | Out-Null

function Download-Checked($url, $path, $hash, $algorithm) {
    if (!(Test-Path $path)) { Invoke-WebRequest $url -OutFile $path }
    if ((Get-FileHash $path -Algorithm $algorithm).Hash.ToLowerInvariant() -ne $hash) {
        throw "Checksum mismatch: $path"
    }
}
function Godot-Checked([string[]] $arguments) {
    & $script:engine @arguments
    if ($LASTEXITCODE -ne 0) { throw "Godot failed with exit $LASTEXITCODE" }
}

$baseUrl = 'https://github.com/godotengine/godot-builds/releases/download/4.3-stable'
$editorZip = Join-Path $tools 'Godot_v4.3-stable_win64.exe.zip'
Download-Checked "$baseUrl/Godot_v4.3-stable_win64.exe.zip" $editorZip 'ad09b7e19949327700dfbe64e35880a2a08091c0751277f5cc21b915e5df9b4fe93fb43c50d6bdfb9d16b46168592491aa698e0d2dbe9f92132e163dd77b97e1' 'SHA512'
Expand-Archive $editorZip -DestinationPath $tools -Force
$script:engine = Join-Path $tools 'Godot_v4.3-stable_win64_console.exe'
if ((& $engine --version) -ne '4.3.stable.official.77dcf97d8') { throw 'Wrong Godot version' }
python "$root/tools/install_export_templates.py" --platform windows
if ($LASTEXITCODE -ne 0) { throw 'Template installation failed' }

$rcedit = Join-Path $tools 'rcedit.exe'
Download-Checked 'https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x64.exe' $rcedit '3e7801db1a5edbec91b49a24a094aad776cb4515488ea5a4ca2289c400eade2a' 'SHA256'
$env:PATH = "$tools;$env:PATH"
Godot-Checked @('--headless', '--editor', '--path', $root, '--import', '--quit')
$exe = Join-Path $export 'Astra-3D-Car-Game-V2.exe'
Godot-Checked @('--headless', '--path', $root, '--export-release', 'Windows x64', $exe)
$versionMatch = [regex]::Match((Get-Content "$root/project.godot" -Raw), '(?m)^config/version="([^"]+)"')
$version = $versionMatch.Groups[1].Value
$metadata = (Get-Item $exe).VersionInfo
if ($metadata.ProductName -ne 'Astra 3D Car Game V2' -or $metadata.FileVersion -ne "$version.0") {
    throw 'Windows executable product/version stamping failed'
}
Godot-Checked @('--headless', '--path', $root, '--script', 'res://tools/make_windows_icon.gd')
python "$root/tools/package_desktop.py" windows
if ($LASTEXITCODE -ne 0) { throw 'Portable package validation failed' }

$compiler = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
if (!(Test-Path $compiler)) {
    choco install innosetup --version=6.4.3 --yes --no-progress
    if ($LASTEXITCODE -ne 0) { throw 'Inno Setup installation failed' }
}
& $compiler "/DAppVersion=$version" "/DExportDir=$export" "/DOutputDir=$output" "/DIconFile=$root/builds/branding/icon.ico" "$root/packaging/windows.iss"
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
$setup = Join-Path $output 'Astra-3D-Car-Game-V2-Windows-x64-Setup.exe'
if (!(Test-Path $setup) -or (Get-Item $setup).Length -lt 1MB) { throw 'Missing/invalid installer' }

# Actual Windows headless runtime test, from outside the source tree.
function Smoke-Test($runtime, $label) {
    $log = Join-Path $env:RUNNER_TEMP "$label.log"
    $process = Start-Process -FilePath $runtime -WorkingDirectory $env:RUNNER_TEMP -ArgumentList "--headless --quit-after 120 --log-file `"$log`" -- --sandbox --quickstart" -PassThru
    if (!$process.WaitForExit(60000)) { $process.Kill(); throw "$label timed out" }
    if ($process.ExitCode -ne 0) { throw "$label exited $($process.ExitCode)" }
    if (!(Test-Path $log)) { throw "$label did not write its startup log" }
    $text = Get-Content $log -Raw
    if ($text -match 'SCRIPT ERROR:|ERROR:|Parse Error|Failed to load') { throw "$label runtime errors: $text" }
    Write-Output "PASSED: $label Windows headless startup"
}
Smoke-Test $exe 'portable'

# Install/shortcut/reinstall/uninstall checks use only this disposable CI runner.
$install = Join-Path $env:RUNNER_TEMP 'Astra installer test'
function Install-Test {
    $process = Start-Process $setup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR=`"$install`"" -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "Installer exited $($process.ExitCode)" }
}
Install-Test
$installedExe = Join-Path $install 'Astra-3D-Car-Game-V2.exe'
if (!(Test-Path $installedExe) -or !(Test-Path "$install/Astra-3D-Car-Game-V2.pck")) { throw 'Installer omitted runtime/data' }
$shortcut = Join-Path ([Environment]::GetFolderPath('Programs')) 'Astra 3D Car Game V2/Astra 3D Car Game V2.lnk'
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
    "Astra 3D Car Game V2 v$version",
    "Source: $(git -C $root rev-parse HEAD)",
    'Godot: 4.3.stable.official.77dcf97d8; official SHA-512 verified release templates',
    "Installer compiler: $((Get-Item $compiler).VersionInfo.FileVersion)",
    'PASSED: x64 PE32+ executable, Godot 4.3 PCK, portable ZIP CRC/structure',
    'PASSED: product name, version metadata and existing project icon',
    'PASSED: portable and installed Windows headless startup',
    'PASSED: silent installation, Start Menu shortcut, reinstallation, uninstall and user-data preservation',
    'NOT TESTED: Windows graphical rendering, interactive gameplay and subjective audio'
)
Set-Content (Join-Path $output 'Windows-validation.txt') $report -Encoding utf8
$checksums = Get-ChildItem $output -File | Where-Object { $_.Extension -in @('.zip', '.exe') } | ForEach-Object {
    "$((Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())  $($_.Name)"
}
Set-Content (Join-Path $output 'SHA256SUMS-Windows.txt') $checksums -Encoding utf8
$report | Write-Output
