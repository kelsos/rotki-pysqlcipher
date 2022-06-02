$TCLTK='tcltk85-8.5.19-17.tcl85.Win10.x86_64'

$PROJECT_DIR = $PWD

function ExitOnFailure {
    param([string]$ExitMessage)
    if (-not ($LASTEXITCODE -eq 0)) {
        echo "`n------------`n"
        echo "$ExitMessage"
        echo "`n------------`n"
        exit 1;
    }
}

if ($Env:CI) {
    echo "::group::Setup Build dependencies"
}

if (-not (Test-Path build\$TCLTK -PathType Container)) {
    echo "Setting up TCL/TK $TCLTK"
    tar -xf "rotki-win-build\$TCLTK.tgz" -C build
    ExitOnFailure("Failed to untar tcl/tk")
}

if ($Env:CI) {
    echo "::addpath::$PWD\build\$TCLTK\bin"
} else {
    $env:Path += ";$PWD\build\$TCLTK\bin"
}

if ($Env:CI) {
    echo "::endgroup::"
    echo "::group::Build SQLCipher"
}

cd sqlcipher
$SQLCIPHER_DIR = $PWD

if (-not (git status --porcelain)) {
    echo "Applying Makefile patch for SQLCipher"
    git apply $PROJECT_DIR\patches\sqlcipher_win.diff
    ExitOnFailure("Failed to apply the Makefile patch for SQLCipher")
}


$OPENSSL_PATH = (Join-Path ${env:ProgramFiles} "OpenSSL-Win64")

if (-not(Test-Path "$OPENSSL_PATH" -PathType Container))
{
    echo "Installing OpenSSL 1.1.1.8"
    choco install -y openssl --version 1.1.1.800 --no-progress
    ExitOnFailure("Installation of OpenSSL Failed")
}

echo "`nSetting up Visual Studio Dev Shell`n"

$BACKUP_ENV = @()
Get-Childitem -Path Env:* | Foreach-Object {
    $BACKUP_ENV += $_
}

$vsPath = &(Join-Path ${env:ProgramFiles(x86)} "\Microsoft Visual Studio\Installer\vswhere.exe") -version '[16.0,)' -property installationpath
Import-Module (Join-Path $vsPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll")

$arch = 64
$vc_env = "vcvars$arch.bat"
echo "Load MSVC environment $vc_env"
$build = (Join-Path $vsPath "VC\Auxiliary\Build")
$env:Path += ";$build"

Enter-VsDevShell -VsInstallPath $vsPath -DevCmdArguments -arch=x64
if (Get-Command "$vc_env" -errorAction SilentlyContinue)
{
    ## Store the output of cmd.exe. We also ask cmd.exe to output
    ## the environment table after the batch file completes
    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    cmd /Q /c "$vc_env && set" 2>&1 | Foreach-Object {
        if ($_ -match "^(.*?)=(.*)$")
        {
            Set-Content "env:\$( $matches[1] )" $matches[2]
        }
    }

    echo "Environment successfully set"
}

if (-not (Test-Path sqlcipher.dll -PathType Leaf))
{
    cd $SQLCIPHER_DIR
    nmake /f Makefile.msc
    ExitOnFailure("Failed to build SQLCipher")

}

# Reset the environment **
Get-Childitem -Path Env:* | Foreach-Object {
    Remove-Item "env:\$($_.Name)"
}

$BACKUP_ENV | Foreach-Object {
    Set-Content "env:\$($_.Name)" $_.Value
}

$env:Path += ";$SQLCIPHER_DIR"

if ($Env:CI) {
    echo "::endgroup::"
    echo "::group::Setup PySQLCipher"
}

cd $PROJECT_DIR

cd pysqlcipher3
$PYSQLCIPHER3_DIR = $PWD

if (-not (git status --porcelain)) {
    echo "Applying setup patch"
    git apply --ignore-whitespace $PROJECT_DIR\patches\pysqlcipher3_win.diff
    ExitOnFailure("Failed to apply pysqlcipher3 patch")
}

if ($Env:CI) {
    echo "::endgroup::"
}