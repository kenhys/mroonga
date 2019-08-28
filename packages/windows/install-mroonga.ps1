Param(
  [Parameter(mandatory=$true)][String]$mariadbVersion,
  [Parameter(mandatory=$true)][String]$platform
)

function Wait-UntilRunning($cmdName) {
  do
  {
    Start-Sleep -s 5
    $Running = Get-Process $cmdName -ErrorAction SilentlyContinue
    Write-Output "Wait-UntilRunning"
    Write-Output ($(Get-Date) - $Running.StartTime).TotalSeconds
  } while (!$Running -or (($(Get-Date) - $Running.StartTime).TotalSeconds -lt 10))
}

function Wait-UntilTerminate($cmdName) {
  do
  {
    Start-Sleep -s 5
    $Running = Get-Process $cmdName -ErrorAction SilentlyContinue
    Write-Output "Wait-UntilTerminate"
  } while ($Running -and $Running.Age.TotalSeconds -lt 10)
}

function Install-Mroonga($mariadbVer, $arch, $installSqlDir) {
  cd "mariadb-$mariadbVer-$arch"
  Start-Process .\bin\mysqld.exe
  Wait-UntilRunning mysqld
  Get-Content "$installSqlDir\install.sql" | .\bin\mysql.exe -uroot
  Start-Process .\bin\mysqladmin.exe -ArgumentList "-uroot shutdown"
  Wait-UntilTerminate mysqld
  cd ..
}

$installSqlDir = ".\share\mroonga"

Install-Mroonga $mariadbVersion $platform $installSqlDir
