$policySetDefinitionName = Deploy-MDFC-Config

$updateCustomALZPolicies = $true # <-- $false = don't update the policy definitions
$policySetDefinitionName = "Deploy-Private-DNS-Zones" # <-- Replace with policy definition name found earlier
$policySetDefinitionLocation = "Hays" # <-- Replace with Definition location found earlier
$policySetDefinitionPath = "./$($policySetDefinitionName).json"
Invoke-WebRequest -Uri https://raw.githubusercontent.com/Azure/Enterprise-Scale/main/src/resources/Microsoft.Authorization/policySetDefinitions/$($policySetDefinitionName).json -OutFile $policySetDefinitionPath
$policySetDef = Get-Content $policySetDefinitionPath | ConvertFrom-Json -Depth 100


# Update all ALZ custom policy definitions first
  if ($updateCustomALZPolicies) {  
    foreach ($policyDefId in $policySetDef.properties.policyDefinitions.policyDefinitionId) {
      write-Host "Processing Policy Definition ID: $($policyDefId)" -ForegroundColor Cyan  
      Write-Host "Checking if Policy Definition ID: $($policyDefId) is built-in or custom" -ForegroundColor Cyan
      if ($policyDefId -match '(\/\w+\/\w+\.\w+\/\w+\/)(\w+)(\/.+)') {
        write-Host "Policy Definition ID: $($policyDefId) is custom, continue update process" -ForegroundColor Cyan 
        $policyDefinitionName = $policyDefId.substring($policyDefId.lastindexof('/') + 1)
        Write-Host "PolicyDefinition Name: $($policyDefinitionName)" -ForegroundColor Cyan
        $policyDefinitionPath = "./$($policyDefinitionName).json"
        Write-Host "PolicyDefinition Path: $($policyDefinitionPath)"
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/Enterprise-Scale/main/src/resources/Microsoft.Authorization/policyDefinitions/$($policyDefinitionName).json" -OutFile $policyDefinitionPath
        $policyDef = Get-Content $policyDefinitionPath | ConvertFrom-Json -Depth 100
        $policyName = $policyDef.name
        $displayName = $policyDef.properties.displayName
        $description = $policyDef.properties.description
        $mode = $policyDef.properties.mode
        $metadata = $policyDef.properties.metadata | ConvertTo-Json -Depth 100
        $parameters = $policyDef.properties.parameters | ConvertTo-Json -Depth 100
        $policyRule = $policyDef.properties.policyRule | ConvertTo-Json -Depth 100
        $policyRule = $policyRule.Replace('[[', '[')
        Write-Host "Creating new Policy Definition in Azure: $($policyName)"
        New-AzPolicyDefinition -Name $policyName -DisplayName $displayname -Description $description -Policy $policyRule -Mode $mode -Metadata $metadata -Parameter $parameters -ManagementGroupName $policySetDefinitionLocation -Verbose
      }
      else 
      {
        write-Host "Policy Definition ID: $($policyDefId) is built-in, nothing to do here" -ForegroundColor Cyan 
      }
      Write-Host ""
    }
  }
# End of updating all ALZ custom policy definitions

$policyName = $policySetDef.name
$displayName = $policySetDef.properties.displayName
$description = $policySetDef.properties.description
$metadata = $policySetDef.properties.metadata | ConvertTo-Json -Depth 100
$parameters = $policySetDef.properties.parameters | ConvertTo-Json -Depth 100
$policyDefinitions = ConvertTo-Json -InputObject @($policySetDef.properties.policyDefinitions) -Depth 100
$policyDefinitions = $policyDefinitions.Replace('[[', '[')
$policyDefinitions = $policyDefinitions -replace '(\/\w+\/\w+\.\w+\/\w+\/)(\w+)(\/.+)', "`${1}$policySetDefinitionLocation`${3}"
New-AzPolicySetDefinition -Name $policyName -DisplayName $displayname -Description $description -PolicyDefinition $policyDefinitions -Metadata $metadata -Parameter $parameters -ManagementGroupName $policySetDefinitionLocation


#import single policy
$policyDefinitionName = "Audit-PrivateLinkDnsZones"
$policyDefinitionPath = "./$($policyDefinitionName).json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Azure/Enterprise-Scale/main/src/resources/Microsoft.Authorization/policyDefinitions/$($policyDefinitionName).json" -OutFile $policyDefinitionPath
Invoke-WebRequest -Uri https://raw.githubusercontent.com/Azure/Enterprise-Scale/main/src/resources/Microsoft.Authorization/policyDefinitions/Deny-EH-MINTLS.json -OutFile $policyDefinitionPath
$policyDef = Get-Content $policyDefinitionPath | ConvertFrom-Json -Depth 100
$policyName = $policyDef.name
$displayName = $policyDef.properties.displayName
$description = $policyDef.properties.description
$mode = $policyDef.properties.mode
$metadata = $policyDef.properties.metadata | ConvertTo-Json -Depth 100
$parameters = $policyDef.properties.parameters | ConvertTo-Json -Depth 100
$policyRule = $policyDef.properties.policyRule | ConvertTo-Json -Depth 100
$policyRule = $policyRule.Replace('[[', '[')
Write-Host "Creating new Policy Definition in Azure: $($policyName)"
New-AzPolicyDefinition -Name $policyName -DisplayName $displayname -Description $description -Policy $policyRule -Mode $mode -Metadata $metadata -Parameter $parameters -ManagementGroupName $policySetDefinitionLocation -Verbose
