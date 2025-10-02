$file1Links = Get-Content "C:\Users\jlangdon\Downloads\file1.txt"
$file2Links = Get-Content "C:\Users\jlangdon\Downloads\file2.txt"

$comparisonResult = Compare-Object -ReferenceObject $file1Links -DifferenceObject $file2Links

if ($comparisonResult) {
    Write-Host "The files are different:"
    $comparisonResult | ForEach-Object {
        Write-Host "$($_.SideIndicator) $($_.InputObject)"
    }
} else {
    Write-Host "The files are identical."
}
