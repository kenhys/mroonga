Param(
  [Parameter(mandatory=$true)][String]$mariadbVersion,
  [Parameter(mandatory=$true)][String]$platform
)

function Wait-UntilRunning($cmdName) {
  $Waiting = $TRUE
  $Count = 1
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
      Write-Output("failed to detect {0} process" -f $cmdName)
      $Count = $Count + 1
      if ($Count -gt 10) {
        $Waiting = $FALSE
      }
    }
  } while ($Waiting)
}

function Wait-UntilTerminate($cmdName) {
  $Waiting = $TRUE
  $Count = 1
  do
  {
    Start-Sleep -s 1
    $Running = Get-Process $cmdName -ErrorAction SilentlyContinue
    if ($Running) {
      $Elapsed = ($(Get-Date) - $Running.StartTime).TotalSeconds
      if ($Elapsed -lt 10) {
        Write-Output("waiting terminate process {0} seconds" -f $Elapsed)
      } else {
        $Waiting = $FALSE
        Write-Output("wait to terminate {0} in 10 seconds" -f $cmdName)
      }
    } else {
      $Count = $Count + 1
      Write-Output("{0} may be terminated" -f $cmdName)
      if ($Count -gt 5) {
        $Waiting = $FALSE
      }
    }
  } while ($Waiting)
}

function Install-Mroonga($mariadbVer, $arch, $installSqlDir) {
  Write-Output("Start to install Mroonga")
  cd "mariadb-$mariadbVer-$arch"
  if ("$mariadbVer" -eq "10.4.7") {
    Write-Output("Clean data directory")
    Remove-Item data -Recurse
    Start-Process .\bin\mysql_install_db.exe
    Start-Sleep -s 10
  }
  Write-Output("Start mysqld.exe")
  Start-Process .\bin\mysqld.exe
  Wait-UntilRunning mysqld
  Write-Output("Execute install.sql")
  Get-Content "$installSqlDir\install.sql" | .\bin\mysql.exe -uroot
  Write-Output("Shutdown mysqld.exe")
  Start-Process .\bin\mysqladmin.exe -ArgumentList "-uroot shutdown"
  Wait-UntilTerminate mysqld
  cd ..
  Write-Output("Finished to install Mroonga")
}

$installSqlDir = ".\share\mroonga"

Install-Mroonga $mariadbVersion $platform $installSqlDir
