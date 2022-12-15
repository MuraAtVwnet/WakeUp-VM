#####################################################
# 停止している VM 起動
#####################################################

# VMs
$Here_WSV12VMs = @"
DMZ-FC02
en-w10IP-Fast
flets
jp-w10-CB
jp-w10IP-Beta
jp-w10IP-Fast
jp-w10IP-Release Preview
jp-w10-LTSB2015
jp-w10-LTSB2016
jp-w10-LTSC2019
jp-w10-LTSC2021
LAN-DC03
LAN-DHCP02
LAN-Remote11
VirusCheck
"@

$Here_WSV11VMs = @"
DMZ-CA01
DMZ-FC01
DMZ-Mail02
DMZ-NS01
DMZ-Web21
LAN-Backup
LAN-DC01
LAN-DHCP01
LAN-File01
LAN-Syslog
"@


##########################################################################
# ログ出力
##########################################################################
function Log(
			$LogString
			){

	# ログの出力先
	$LogPath = "C:\Log"

	# ログファイル名
	$LogName = "VM_WakeUp"

	$Now = Get-Date

	# Log 出力文字列に時刻を付加(YYYY/MM/DD HH:MM:SS.MMM $LogString)
	$Log = $Now.ToString("yyyy/MM/dd HH:mm:ss.fff") + " "
	$Log += $LogString

	# ログファイル名が設定されていなかったらデフォルトのログファイル名をつける
	if( $LogName -eq $null ){
		$LogName = "LOG"
	}

	# ログファイル名(XXXX_YYYY-MM-DD.log)
	$LogFile = $LogName + "_" +$Now.ToString("yyyy-MM-dd") + ".log"

	# ログフォルダーがなかったら作成
	if( -not (Test-Path $LogPath) ) {
		New-Item $LogPath -Type Directory
	}

	# ログファイル名
	$LogFileName = Join-Path $LogPath $LogFile

	# ログ出力
	Write-Output $Log | Out-File -FilePath $LogFileName -Encoding Default -append

	# echo させるために出力したログを戻す
	Return $Log
}


####################################
# ヒア文字列を配列にする
####################################
function HereString2StringArray( $HereString ){
	$Temp = $HereString.Replace("`r","")
	$StringArray = $Temp.Split("`n")
	return $StringArray
}


####################################
# 停止している VM を起動する
####################################
function WakeUp([string]$VM_Name){
	$VM = Get-VM -Name $VM_Name  -ErrorAction SilentlyContinue

	if($VM -eq $null){
		return
	}

	if( ($VM.State -eq [Microsoft.HyperV.PowerShell.VMState]::Off) -or ($VM.State -eq [Microsoft.HyperV.PowerShell.VMState]::Saved) ){
		$VM_Name = $VM.Name
		Log "$VM_Name が停止しているので起動"
		Start-VM -VM $VM
	}
}


####################################
# Main
####################################

$HostName = $Env:COMPUTERNAME

if( $HostName -eq "WSV11" ){
	[array]$VMs = HereString2StringArray $Here_WSV11VMs
}
else{
	[array]$VMs = HereString2StringArray $Here_WSV12VMs
}

foreach( $VM in $VMs){
	WakeUp $VM
}
