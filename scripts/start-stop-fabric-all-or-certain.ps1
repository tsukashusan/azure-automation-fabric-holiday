Param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionID,
    [Parameter(Mandatory=$true)]
    [string]$operation,
    [Parameter(Mandatory=$false)]
    [array]$capacityNames
)

#$operation = "suspend" 
#$operation = "resume"

Connect-AzAccount -Identity

$tokenObject = Get-AzAccessToken -ResourceUrl "https://management.azure.com/"
$token = $tokenObject.Token

$url = "https://management.azure.com/subscriptions/$SubscriptionID/providers/Microsoft.Fabric/capacities?api-version=2023-11-01"
Write-Verbose $url

$headers = @{
    'Content-Type' = 'application/json'
    'Authorization' = "Bearer $token"
}

if($null -not $capacityNames){
    Write-Verbose $capacityNames
    Write-Verbose "GetType: $($capacityNames.GetType())"
    Write-Verbose "Length: $($capacityNames.Length)"
}else{
    Write-Verbose "capacityNames is null or empty"
}


Invoke-RestMethod -Uri $url -Method Get -Headers $headers | ForEach-Object -Process{
    $c = 0
    $_.value| ForEach-Object -Process{
        #Write-Verbose $_
        Write-Verbose "count: $($c)"
        Write-Verbose $_.properties.state
        Write-Verbose "capacity name: $($_.name)"
        if ((($capacityNames.Count -eq 0) -or ($capacityNames.Contains($_.name))) -and (("suspend" -eq $operation) -and ("Active" -eq $_.properties.state)) -or (("resume" -eq $operation) -and ("Paused" -eq $_.properties.state))) {
          $url = "https://management.azure.com/$($_.id)/$operation" + "?api-version=2023-11-01"
          $headers = @{
              'Content-Type' = 'application/json'
              'Authorization' = "Bearer $token"
          }
          Write-Verbose $url
          $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers                 
          Write-Verbose $response
        }else{
            Write-Verbose "not active : $($_.properties.state)"
        }
        $c = $c + 1
  }
}
