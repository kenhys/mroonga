Param(
  [Parameter(mandatory=$true)][String]$mariadbVersion,
  [Parameter(mandatory=$true)][String]$platform
)

function Wait-UntilRunning($cmdName) {
  $Waiting = $TRUE
  do
  {
    Start-Sleep -s 1
    $Running = Get-Process $cmdName -ErrorAction SilentlyContinue
    if ($Running) {
      $Elapsed = ($(Get-Date) - $Running.StartTime).TotalSeconds
      if ($Elapsed -lt 10) {
        Write-Output("waiting {0} seconds" -f $Elapsed)
      } else {
        $Waiting = $FALSE
        Write-Output("wait to run {0} in 10 seconds" -f $cmdName)
      }
    } else {
      $Waiting = $FALSE
    }
  } while ($Waiting)
}

function Wait-UntilTerminate($cmdName) {
  $Waiting = $TRUE
  do
  {
    $Running = Get-Process $cmdName -ErrorAction SilentlyContinue
    Start-Sleep -m 500
    if ($Running) {
      $Elapsed = ($(Get-Date) - $Running.StartTime).TotalSeconds
      if ($Elapsed -lt 10) {
        Write-Output("waiting terminate process {0} seconds" -f $Elapsed)
      } else {
        $Waiting = $FALSE
        Write-Output("wait to terminate {0} in 10 seconds" -f $cmdName)
      }
    } else {
      Write-Output("{0} was terminated" -f $cmdName)
      $Waiting = $FALSE
    }
  } while ($Waiting)
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
