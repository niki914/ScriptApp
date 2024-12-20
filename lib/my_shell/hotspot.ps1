Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

$MSG_1 = "the hotspot is opened ;)"
$MSG_2 = "failed to open the hotspot.."
$MSG_3 = "the hotspot was already opened ;)"

Function Await-AsyncOperation {
    param (
        [Parameter(Mandatory)]
        [System.Object] $AsyncOperation,
        [Parameter(Mandatory)]
        [Type] $ResultType
    )
    
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($AsyncOperation))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}

$connectionProfile = [Windows.Networking.Connectivity.NetworkInformation, Windows.Networking.Connectivity, ContentType = WindowsRuntime]::GetInternetConnectionProfile()
$tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager, Windows.Networking.NetworkOperators, ContentType = WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)

if ($tetheringManager.TetheringOperationalState -ne 1) {
    $operationResult = Await-AsyncOperation $tetheringManager.StartTetheringAsync() ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
    
    Start-Sleep -Milliseconds 200

    if ($tetheringManager.TetheringOperationalState -eq 1) 
    { return $MSG_1 } 
    else
    { return $MSG_2 }
}
else {
    return $MSG_3
}

