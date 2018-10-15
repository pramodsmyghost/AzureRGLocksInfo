<#
    .SYNOPSIS
    This script will check if the LOCKS are present on the US-HOST02 Resorce Groups if not it will generate a report and store it in storage account.
    
    .DESCRIPTION
    - This script will check if the LOCKS are present on the US-HOST02 Resorce Groups if not it will generate a report and store it in storage account.
     
    .NOTES
    Author      :   Ankita Chaudhari
    Modified By :   Pramod Reddy
    Company     :   LTI
    Created     :   14-09-2018
    Updated     :   03-10-2018
    Version     :   1.0
    
    .INPUTS
    
    .OUTPUTS
    Report in the storage account.

    .Note 
    All the modules should be updated in the automation account.
    
#>

Param(

    [Parameter(Mandatory= $true)]  
    [PSCredential]$AzureOrgIdCredential,

    [Parameter(Mandatory= $true)]
    [string]$SubcriptionID = "bb3d0ed0-bf9b-442d-83d5-3b059843dd52"

)

#   Logging in to Azure
$Null = Login-AzureRMAccount -Credential $AzureOrgIdCredential  
$Null = Get-AzureRmSubscription -SubscriptionID $SubcriptionID | Select-AzureRMSubscription

#   Getting Storage Info 
$StorageAccountName = "use2host02mivmstrg001"
$StorageAccountRG = (Get-AzureRmStorageAccount | where StorageAccountName -eq $StorageAccountName).ResourceGroupName
$StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $StorageAccountRG -Name $StorageAccountName).key1
$Context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

#   Set the Current Storage Account to the approperiate location
Write-Output "Setting the Current Storage Account to the approperiate location"
Set-AzureRmCurrentStorageAccount -StorageAccountName $StorageAccountName -ResourceGroupName $StorageAccountRG

$date = Get-Date -Format "ddMMMyyyy"
$date = $date.Replace(" ","_")
$CSVName = $date+"_USHost02_Lock_NotApplied.csv"
$ResourceName = @()

    $ResourceGroupsList = Get-AzureRmResourceGroup 
    foreach($ResourceGroups in $ResourceGroupsList)
    {
        #Obtaining Resource Group Name
        $RGName = $ResourceGroups.ResourceGroupName
        $LockName = $RGName+"-"+"Locks"
    
        $LockInfo = Get-AzureRmResourceLock -ResourceGroupName $RGName -LockName $LockName
        if($LockInfo -eq $null -or $LockInfo -eq "")
        {
            Write-Output "Resource Lock $LockName not present on Resource Group $RGName"
            Write-Output "Exporting information to Excel"
            $ResourceName = New-Object System.Object
            $ResourceName | Add-Member -MemberType NoteProperty -Name "RGName" -Value $RGName
            $ResourceName | export-csv "$CSVName" -NoTypeInformation -Append
        }
    }

Set-AzureStorageBlobContent -Container "resourcelockstatus-logs" -File $CSVName -Blob $CSVName -Context $Context
