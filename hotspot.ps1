Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

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

$connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
$tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)

if ($tetheringManager.TetheringOperationalState -ne 1) {
    $operationResult = Await-AsyncOperation $tetheringManager.StartTetheringAsync() ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
    
    # —”≥Ÿ500ms‘ŸºÏ≤È
    Start-Sleep -Milliseconds 20

    if ($tetheringManager.TetheringOperationalState -eq 1) {
        return "Hotspot started successfully."
    } else {
        return "Failed to start Hotspot. API Result: $operationResult, Actual State: $($tetheringManager.TetheringOperationalState)"
    }
} else {
    return "Hotspot is already active."
}