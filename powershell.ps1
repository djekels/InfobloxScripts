$bloxarray = Get-Content reverses.txt
Get-WmiObject microsoftdns_zone -computer $computer -Credential $domcred -namespace root/microsoftdns -filter "reverse = true" | %{if($bloxarray -contains $_.name){Write-Host $_.name; $_.delete()}}
