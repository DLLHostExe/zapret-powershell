# bol-van, sevcator and others & made by <3
Clear-Host
$folderPath = "C:\Windows\Zapret"
$hostlist = "--hostlist-exclude=`"$folderPath\list-exclude.txt`" --hostlist-auto=`"$folderPath\list-auto.txt`""
$ARGS = "--wf-tcp=80,443 --wf-udp=80,443,50000-50099 "
$ARGS += "--filter-udp=443 $hostlist --dpi-desync=fake --dpi-desync-repeats=6 --dpi-desync-fake-quic=`"$folderPath\quic-google.bin`" --new "
$ARGS += "--filter-udp=443 --dpi-desync=fake --dpi-desync-repeats=11 $autohostlist --new "
$ARGS += "--filter-udp=50000-50100 --ipset=$MODPATH/ipset-discord.txt --dpi-desync=fake --dpi-desync-any-protocol --dpi-desync-cutoff=d3 --dpi-desync-repeats=6 --new "
$ARGS += "--filter-tcp=443 $hostlist --dpi-desync=fake --dpi-desync-autottl=2 --dpi-desync-repeats=6 --dpi-desync-fooling=badseq --dpi-desync-fake-tls=`"$folderPath\tls-google.bin`" "
$ARGS += "--filter-tcp=443 --dpi-desync=fake,multidisorder --dpi-desync-split-pos=midsld --dpi-desync-repeats=6 --dpi-desync-fooling=badseq,md5sig $autohostlist --new"
Write-Host "  ______                    _                                          "
Write-Host " |___  /                   | |                                         "
Write-Host "    / / __ _ _ __  _ __ ___| |_ ______ ___ __ _ _ __   __ _ _ __ _   _ "
Write-Host "   / / / _` | '_ \| '__/ _ \ __|______/ __/ _` | '_ \ / _` | '__| | | |"
Write-Host "  / /_| (_| | |_) | | |  __/ |_      | (_| (_| | | | | (_| | |  | |_| |"
Write-Host " /_____\__,_| .__/|_|  \___|\__|      \___\__,_|_| |_|\__,_|_|   \__, |"
Write-Host "            | |                                                   __/ |"
Write-Host "            |_|                                                  |___/ "
Write-Host "Installation with addons of bol-van software. @ follow sevcator.t.me !!"
function Check-Admin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Check-Admin)) {
    Add-Type -AssemblyName System.Windows.Forms 
    Write-Host "- Run PowerShell as administrator rights!"
    return
}
$initialDirectory = Get-Location
$version = [System.Environment]::OSVersion.Version
$windows10Version = New-Object System.Version(10, 0)
if ($version -gt $windows10Version) {
    Write-Output "- Windows version: $version"
} else {
    Write-Host "- Your version of Windows is old!"
    return
}
function Check-ProcessorArchitecture {
    $processor = Get-WmiObject -Class Win32_Processor
    return $processor.AddressWidth -eq 64
}
if (Check-ProcessorArchitecture) {
    Write-Host "- CPU Architecture is 64-bit"
} else {
    Write-Host "- CPU Architecture is not 64-bit"
    return
}
if (Test-Path "$folderPath\uninstall.cmd") {
    & "$folderPath\uninstall.cmd" *> $null
}
# Source: GitHub - censorliber/zapret
function Set-DNS {
    $primaryDNS = "185.222.222.222"
    $secondaryDNS = "45.11.45.11"

    try {
        $interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } -ErrorAction Stop
    } catch {
        Write-Host "- Failed to get active network adapters: $_" -ForegroundColor Yellow
        return
    }

    if ($interfaces.Count -eq 0) {
        Write-Host "- The network adapters not found" -ForegroundColor Red
        return
    }

    foreach ($interface in $interfaces) {
        try {
            Write-Host "- Configuring DNS for $($interface.InterfaceAlias)"
            Set-DnsClientServerAddress -InterfaceAlias $interface.InterfaceAlias -ServerAddresses $primaryDNS, $secondaryDNS -ErrorAction Stop

            Write-Host "- Disabling IPv6 for $($interface.InterfaceAlias)"
            Disable-NetAdapterBinding -Name $interface.InterfaceAlias -ComponentID ms_tcpip6 -ErrorAction Stop
        } catch {
            Write-Host "- Failed set configuration to adapter $($interface.InterfaceAlias): $_" -ForegroundColor Yellow
        }
    }
}
Set-DNS
Write-Host "- Terminating processes"
$processesToKill = @("GoodbyeDPI.exe", "winws.exe", "zapret.exe")
foreach ($process in $processesToKill) {
    Stop-Process -Name $process -Force -ErrorAction SilentlyContinue | Out-Null
}
Write-Host "- Removing services"
$servicesToStop = @("zapret", "winws1", "goodbyedpi", "windivert", "windivert14")
foreach ($service in $servicesToStop) {
    $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue | Out-Null

    if ($serviceStatus) {
        try {
            Stop-Service -Name $service -Force -ErrorAction Stop
        } catch {
            Write-Host ("{0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Red
        }
        
        try {
            sc.exe delete $service -ErrorAction Stop | Out-Null
        } catch {
            Write-Host ("{0}: {1}" -f $service, $_.Exception.Message) -ForegroundColor Yellow
	    Write-Host "If you have problems, try restart your machine!" -ForegroundColor Yellow
        }
    } else {
    
    }
}
if (Test-Path $folderPath) {
    $items = Get-ChildItem -Path $folderPath -Recurse
    $filesToRemove = $items | Where-Object { $_.PSIsContainer -eq $false -and $_.Extension -ne ".txt" }
    foreach ($file in $filesToRemove) {
        try {
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
        } catch {
            Write-Warning "Failed to remove $($file.FullName): $_"
        }
    }
} else {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
}
if (-not (Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory | Out-Null
}
Write-Host "- Flushing DNS cache"
ipconfig /flushdns | Out-Null
$exclusionPath = "$folderPath\winws.exe"
Write-Host "- Adding exclusion"
if (-not (Test-Path $exclusionPath)) {
    New-Item -Path $exclusionPath -ItemType File | Out-Null
}
try {
    Add-MpPreference -ExclusionPath $exclusionPath
    Start-Sleep -Seconds 5
} catch {
    Write-Host "- Error adding exclusion? If you have another AntiMalware software, add exclusion C:\Windows\Zapret\winws.exe, C:\Windows\Zapret\WinDivert.dll, C:\Windows\Zapret\WinDivert64.sys" -ForegroundColor Yellow
}
Write-Host "- Downloading files"
$files = @(
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/WinDivert.dll"; Name = "WinDivert.dll"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/WinDivert64.sys"; Name = "WinDivert64.sys"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/cygwin1.dll"; Name = "cygwin1.dll"},
    @{Url = "https://github.com/bol-van/zapret-win-bundle/raw/refs/heads/master/zapret-winws/winws.exe"; Name = "winws.exe"},
    @{Url = "https://raw.githubusercontent.com/bol-van/zapret-win-bundle/refs/heads/master/zapret-winws/ipset-discord.txt"; Name = "ipset-discord.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/list.txt"; Name = "list.txt"},
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/list-exclude.txt"; Name = "list-exclude.txt"},
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/tls_clienthello_www_google_com.bin"; Name = "tls-google.bin"}
    @{Url = "https://github.com/bol-van/zapret/raw/refs/heads/master/files/fake/quic_initial_www_google_com.bin"; Name = "quic-google.bin"}
    @{Url = "https://raw.githubusercontent.com/sevcator/zapret-powershell/refs/heads/main/files/uninstall.cmd"; Name = "uninstall.cmd"}
)
foreach ($file in $files) {
    try {
        Invoke-WebRequest -Uri $file.Url -OutFile "$folderPath\$($file.Name)" -ErrorAction Stop | Out-Null
    } catch {
        Write-Host ("{0}: {1}" -f $($file.Name), $_.Exception.Message) -ForegroundColor Red
    }
}
Set-Location $folderPath | Out-Null
Write-Host "- Creating service"
try {
    sc.exe create winws1 binPath= "`"$folderPath\winws.exe $ARGS`"" DisplayName= "zapret DPI bypass" start= auto | Out-Null
    sc.exe start winws1 | Out-Null
} catch {
    Write-Host ("Failed to create or start service: {0}" -f $_.Exception.Message) -ForegroundColor Red
}
function hosts-Config {
    $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
    $canaryHostsFile = "canary-hosts"

    Write-Host "- Modifying hosts"
    
    if (Test-Path $canaryHostsFile) {
        try {
            $canaryHosts = Get-Content -Path $canaryHostsFile -ErrorAction Stop
            Add-Content -Path $hostsFile -Value $canaryHosts
        } catch {
            Write-Host "- Error to add hosts from ${canaryHostsFile}: $($_)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "- The file ${canaryHostsFile} not found" -ForegroundColor Yellow
    }
}
hosts-Config
Write-Host "- Done!"
Write-Host "- To remove Zapret, run script located in $folderPath\uninstall.cmd as administrator!"
Write-Host "*** sevcator.t.me / sevcator.github.io ***"
Set-Location $initialDirectory
