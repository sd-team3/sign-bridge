$ErrorActionPreference = 'Stop'
$serverRoot = Split-Path $PSScriptRoot -Parent
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'sign-bridge-word-exam-tests'
$classes = Join-Path $testRoot 'classes'
New-Item -ItemType Directory -Force $classes | Out-Null
$h2 = Join-Path $testRoot 'h2.jar'
if (!(Test-Path $h2)) {
    Invoke-WebRequest 'https://repo.maven.apache.org/maven2/com/h2database/h2/2.3.232/h2-2.3.232.jar' -OutFile $h2
}
$classpath = "$classes;$serverRoot/src/main/resources;$serverRoot/target/classes;$serverRoot/target/dependency/*;$h2"
$source = Join-Path $serverRoot 'src/main/java/com/soldesk'
& javac --release 17 -encoding UTF-8 -cp $classpath -d $classes `
    "$source/service/SignLearningApiService.java" "$source/service/WordExamService.java" "$source/service/WordExamSchema.java" `
    "$source/mapper/WordExamMapper.java" "$source/controller/WordExamController.java" `
    "$source/controller/ExamController.java" "$PSScriptRoot/WordExamSmoke.java"
if ($LASTEXITCODE -ne 0) { throw 'Java compilation failed' }
& java "-Dlogback.configurationFile=$PSScriptRoot/logback-test.xml" -cp $classpath WordExamSmoke $serverRoot
if ($LASTEXITCODE -ne 0) { throw 'Java tests failed' }
& npm install --prefix $testRoot --no-audit --no-fund jsdom@26
if ($LASTEXITCODE -ne 0) { throw 'Test dependency installation failed' }
$previousNodePath = $env:NODE_PATH
try {
    $env:NODE_PATH = Join-Path $testRoot 'node_modules'
    & node "$PSScriptRoot/word-exam-ui.cjs"
    if ($LASTEXITCODE -ne 0) { throw 'UI tests failed' }
    & node "$PSScriptRoot/sign-auto-capture.cjs"
    if ($LASTEXITCODE -ne 0) { throw 'Automatic recording tests failed' }
    & node "$PSScriptRoot/comparison-ui.cjs"
    if ($LASTEXITCODE -ne 0) { throw 'Comparison UI tests failed' }
} finally { $env:NODE_PATH = $previousNodePath }
