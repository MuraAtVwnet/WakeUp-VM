#####################################################
# 停止している VM 起動
#####################################################

# VMs
$Here_WSV12VMs = @"
DMZ-FC02
en-w11IP-Canary
flets
jp-w10-LTSB2015
jp-w10-LTSB2016
jp-w10-LTSC2019
jp-w10-LTSC2021
jp-w11-CB
jp-w11-Dev
jp-w11-LTSC2024
jp-w11IP-Beta
jp-w11IP-Canary
jp-w11IP-Release Preview
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
LAN-DC01
LAN-DHCP01
LAN-File01
LAN-Syslog
"@



# トークンファイル
$G_TokenFileName = "TokenFile.txt"



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
# メッセージを送る
####################################
function SendMessage([string]$Message){

	# トークンファイルの取得
	$TokenFileFullPath = Join-Path $PSScriptRoot $G_TokenFileName
	if( -not (Test-Path $TokenFileFullPath)){
		return
	}

	try{
		[array]$TokenData = Get-Content -Path $TokenFileFullPath
	}
	catch{
		Log "[FAIL] !!!!!!!! $TokenFileFullPath read error. !!!!!!!!"
		exit
	}

	$Token = $TokenData[0]

	$Channel = $TokenData[1]
	if(( $Token -eq $null ) -or ( $Channel -eq $null )){
		Log "[ERROR] !!!!!!!! $TokenFileFullPath format error. !!!!!!!!"
		return
	}

	$url = "https://slack.com/api/chat.postMessage"

	$body = @{
		token = $Token
		channel = $Channel
		text = $Message
	}
	$Dummy = Invoke-RestMethod -Method Post -Uri $url -Body $body
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
		SendMessage "Start VM : $VM_Name"
		Start-VM -VM $VM
	}
}


####################################
# Main
####################################

$HostName = $Env:COMPUTERNAME

if( $HostName -eq "WSV11" ){
	[array]$VMs = HereString2StringArray $Here_WSV11VMs
	$TergetHost = "WSV12"
}
else{
	[array]$VMs = HereString2StringArray $Here_WSV12VMs
	$TergetHost = "WSV11"
}

foreach( $VM in $VMs){
	WakeUp $VM
}

if( -not (Test-NetConnection $TergetHost).PingSucceeded ){
	$Message = "$TergetHost is down !!"
	Log $Message
	SendMessage $Message
}

Log "Check End"

