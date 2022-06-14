$TCLTK='tcltk85-8.5.19-17.tcl85.Win10.x86_64'

function ExitOnFailure {
    param([string]$ExitMessage)
    if (-not ($LASTEXITCODE -eq 0)) {
        echo "`n------------`n"
        echo "$ExitMessage"
        echo "`n------------`n"
        exit 1;
    }
}

$SOURCE_DIR = $PWD
$BUILD_DIR = "$Env:Temp\pybuild"

$SQLCIPHER_DIR = "$SOURCE_DIR\sqlcipher"
$PYSQLCIPHER_DIR = "$SOURCE_DIR\pysqlcipher3"

if (Test-Path $BUILD_DIR -PathType Container) {
  echo "$BUILD_DIR already exists cleaning up"
  Remove-Item -Recurse -Force $BUILD_DIR
}

$TCLTK_DIR = "$Env:Temp\$TCLTK"

if (-not (Test-Path $TCLTK_DIR -PathType Container)) {
    echo "Setting up TCL/TK $TCLTK"
    tar -xf "$SOURCE_DIR\rotki-win-build\$TCLTK.tgz" -C $Env:Temp
    ExitOnFailure("Failed to untar tcl/tk")
}

echo "Copying submodules to $BUILD_DIR"

Copy-Item -Path "$PYSQLCIPHER_DIR" -Destination "$BUILD_DIR" -Recurse -Force
Copy-Item -Path "$SQLCIPHER_DIR" -Destination "$BUILD_DIR\" -Recurse -Force

echo "Copying win/build.ps1"

Copy-Item "$SOURCE_DIR\scripts\win\build.ps1" -Destination "$BUILD_DIR"

echo "Preparing pysqlcipher3 setup patch"

choco install -y patch --no-progress

if ((-not ($env:VIRTUAL_ENV)) -and (-not ($Env:CI))) {
    if ((-not (Test-Path "$Env:Temp\.venv" -PathType Container))) {
        cd "$Env:Temp"
        pip install virtualenv --user
        echo "Creating .venv"
        python -m virtualenv .venv
        ExitOnFailure("Failed to create rotki VirtualEnv")
    }

    echo "Activating .venv"
    & $Env:Temp\.venv\Scripts\activate.ps1
    ExitOnFailure("Failed to activate rotki VirtualEnv")
}

cd "$SOURCE_DIR\patches"
pip install -r requirements.txt
python patch-gen.py --platform win

cd "$BUILD_DIR"

patch -l -i "$SOURCE_DIR\patches\pysqlcipher3.diff"

echo "Copying OpenSSL to build dir"
Copy-Item -Path "$SOURCE_DIR\openssl" -Destination "$BUILD_DIR\" -Recurse -Force

echo $BUILD_DIR
