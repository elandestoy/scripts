#
# Script to apply a tag in McAfee ePo from powershell.
#
# -- v1.0.1
#
# Setting Variables
#
$epouser = "username"
$epopass = "password"
$epohost = "EPOSERVER:PORT"
$compName = $env:computername
$mcagent = "C:\Program Files\McAfee\Agent\maconfig.exe"
$ScriptRegPath = "HKLM:\SOFTWARE\ePOpswhScript"
$ScriptRUNdate = get-date -Format yyyy-MM-dd
$ScriptVer = "1.0.1"


#
# Check for Powershell_ePOSecurityTags
#
If (!(Test-Path -Path $ScriptRegPath)) {
	New-Item -Path $ScriptRegPath -Force
	New-ItemProperty -Path $ScriptRegPath -Name ScriptVer -Value $ScriptVer
	New-ItemProperty -Path $ScriptRegPath -Name ScriptLASTrun -Value $ScriptRUNdate

}# else {
#	$GetScriptVer = Get-ItemProperty -Path $ScriptRegPath -Name ScriptVer 
#	$GetScriptRUNdate = Get-ItemProperty -Path $ScriptRegPath -Name ScriptLASTrun
#	$GetScriptRUNdate = Get-Date $GetScriptRUNdate.ScriptLASTrun
#	$GetScriptnextRUNdate = $GetScriptRUNdate.AddDays(4)
#		
#		If ($ScriptRUNdate -lt $GetScriptnextRUNdate) {
#			stop-process -Id $PID
#		}
#}
#{ write-host SI } else { write-host NO}

	add-type @"
	using System.Net;
	using System.Security.Cryptography.X509Certificates;
	public class TrustAllCertsPolicy : ICertificatePolicy {
		public bool CheckValidationResult(
			ServicePoint srvPoint, X509Certificate certificate,
			WebRequest request, int certificateProblem) {
			return true;
		}
	}
"@
	[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
	[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
	#Pop-Location
	$wc = new-object System.net.WebClient
	$wc.Credentials = new-object System.Net.NetworkCredential($epouser, $epopass)
	
	#
	# Check Mcafee Agent and Tag NoAgent  
	#
	If (!(Test-Path -Path $mcagent)) {
		if (Test-Path -Path "C:\Program Files(x86)\McAfee\Common Framework\maconfig.exe") {$mcagent = "C:\Program Files(x86)\McAfee\Common Framework\maconfig.exe"}
		else {
			$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=NoAgent"
			$wc.DownloadString($url)
			#stop-process -Id $PID
		}
	}

	#
	# Checking Windows Device Guard Status
 	#
	$DevGuardStatus = Get-CimInstance –ClassName Win32_DeviceGuard –Namespace root\Microsoft\Windows\DeviceGuard
	if ($DevGuardStatus.SecurityServicesRunning -contains 1){
		$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=WinCredentialGuard"
		$wc.DownloadString($url)
		$ComplianceStatus = 1
	}

	#
	# Checking Windows Defender Network Protection Status
	#
	#	$WDMPSettigs = Get-MpPreference
    #if ($WDMPSettigs.EnableNetworkProtection -contains 1) {
	#	$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=WinNetworkProtection"
	#	$wc.DownloadString($url)
	#	$ComplianceStatus = ($ComplianceStatus + 1)
	#} 
	
	#
	# Checking Windows AppLocker
	#
	$AppLocker = Get-AppLockerPolicy -Effective
	if ($AppLocker.RuleCollectionTypes -ne $null) {
		$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=WinAppLoker"
		$wc.DownloadString($url)
		$ComplianceStatus = ($ComplianceStatus + 1)
    } 
	
	#
	# Checking Windows Firewall
	#
	$FirewallDomain = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile"
	$FirewallPublic = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile"
	$FirewallStandard = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile"
	if ($FirewallDomain.EnableFirewall -eq 1 -And $FirewallPublic.EnableFirewall -eq 1 -And $FirewallStandard.EnableFirewall -eq 1) { 
		$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=WinFirewall"
		$wc.DownloadString($url)
		$ComplianceStatus = ($ComplianceStatus + 1)
	} 
	
	#
	# Checking LAPS 
	#
	if (Test-Path -Path "HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd") { 
		$LAPS = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd"
		If ($LAPS.AdmPwdEnabled -eq 1) {
			$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=WinLAPS"
			$wc.DownloadString($url)
			$ComplianceStatus = ($ComplianceStatus + 1)
		}
	} 

	#
	# Checking Windows Bitlocker 
	#
	$BitLockerStatus = Get-BitLockerVolume
	if ($BitLockerStatus.VolumeStatus -eq "FullyEncrypted") { 
		$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=WinBitLocker"
		$wc.DownloadString($url)
		$ComplianceStatus = ($ComplianceStatus + 1)
	} 
	
	#
	# Checking Windows Disable Features 
	#
	$WinFeatures = Get-WindowsOptionalFeature -Online | where state -eq 'Disabled'
	if ($WinFeatures.FeatureName -eq "SMB1Protocol" -And $WinFeatures.FeatureName -eq "MicrosoftWindowsPowerShellV2" ) { 
		$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=WinFeaturesDisabled"
		$wc.DownloadString($url)
		$ComplianceStatus = ($ComplianceStatus + 1)
	} 

	#
	# Checking compliance
	#
	If ($ComplianceStatus -eq 6) {
		$url = "https://$epohost/remote/system.applyTag?names=$compName&tagName=WinCompliance"
		$wc.DownloadString($url)
	}

	#
	# Set Bios Version and set Agent Custom property 1.
	#
	$biosver = wmic bios get SMBIOSBIOSVersion
	& $mcagent "-custom" "-prop1" "$biosver"
	stop-process -Id $PID
