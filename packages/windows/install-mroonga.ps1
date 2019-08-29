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
  Write-Output("Start to install Mroonga")
  cd "mariadb-$mariadbVer-$arch"
  Write-Output("Start mysqld.exe")
  Start-Process .\bin\mysqld.exe
  Start-Sleep -s 10
  Write-Output("Execute install.sql")
  Get-Content "$installSqlDir\install.sql" | .\bin\mysql.exe -uroot
  Write-Output("Shutdown mysqld.exe")
  Start-Process .\bin\mysqladmin.exe -ArgumentList "-uroot shutdown"
  Start-Sleep -s 10
  cd ..
  Write-Output("Finished to install Mroonga")
}

$installSqlDir = ".\share\mroonga"

Install-Mroonga $mariadbVersion $platform $installSqlDir
