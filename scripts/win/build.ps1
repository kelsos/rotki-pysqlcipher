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

echo "Building OpenSSL"
choco install -y activeperl --no-progress

cd openssl

perl ./Configure VC-WIN64A no-shared no-asm no-idea no-camellia \
  no-seed no-bf no-cast no-rc2 no-rc4 no-rc5 no-md2 \
  no-md4 no-ecdh no-sock no-ssl3 \
  no-dsa no-dh no-ec no-ecdsa no-tls1 \
  no-rfc3779 no-whirlpool no-srp \
  no-mdc2 no-ecdh no-engine no-srtp

nmake

echo "OpenSSL Build Complete"
