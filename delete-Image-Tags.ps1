<# 
.DESCRIPTION
This script is to check and remove the old docker images in an azure container registry

.PARAMETER AzureRegistryName
Define Azure Container Registry Name

.PARAMETER Repository
Specify repository to cleanup (if not specified will default to all repositories within the registry)

.PARAMETER ImagestoKeep
Number of images to retain per respository

.PARAMETER EnableDelete
Enable deletion or just run in scan mode to know the images needs to be deleted

.NOTES

#>

# Parameters
$AzureRegistryName = ""
$ImagestoKeep = 20
$EnableDelete = "no"
$Repository = ""


# Main
$imagesDeleted = 0

if ($Repository){
    $RepoList = @("", "", $Repository)
}
else {
    Write-Host "Getting list of all repositories in container registry: $AzureRegistryName"
    $RepoList = az acr repository list --name $AzureRegistryName --output table
}

for($index=2; $index -lt $RepoList.length; $index++){
    $RepositoryName = $RepoList[$index]

    write-host ""
    Write-Host "Checking repository: $RepositoryName"
    $RepositoryTags = ((Get-AzContainerRegistryTag -RegistryName $AzureRegistryName -RepositoryName $RepositoryName).Tags | Sort-Object -Property CreatedTime -Descending).Name
    write-host "# Total images:"$RepositoryTags.length" # Images to keep:"$ImagestoKeep

    if ($RepositoryTags.length -gt $ImagestoKeep) {
        write-host "Deleting surplus images..."
        for ($item=$ImagestoKeep; $item -lt $RepositoryTags.length; $item++) {
            $ImageName = $RepositoryName + ":" + $RepositoryTags[$item]
            $imagesDeleted++
            if ($EnableDelete -eq "yes") {
                write-host "deleting:"$ImageName
                Remove-AzContainerRegistryTag -RepositoryName $RepositoryName -RegistryName $AzureRegistryName -Name $RepositoryTags[$item]
            }
            else {
                write-host "dummy delete:"$ImageName
            }
        }
    }
    else {
        write-host "No surplus images to delete."
    }
}

write-host ""
Write-Host "ACR cleanup completed"
write-host "Total images deleted:"$imagesDeleted