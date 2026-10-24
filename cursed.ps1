Import-Module ActiveDirectory; $password=Read-Host 'Password for all new users' -AsSecureString; $dns=(Get-ADDomain).DNSRoot; Get-Content .\Users.txt | ForEach-Object { $u=$_.Trim(); if ($u) {
$given,$surname=$u -split '\.',2; New-ADUser -Name $u -SamAccountName $u -UserPrincipalName "$u@$dns" -GivenName $given -Surname $surname -AccountPassword $password -Enabled $true -ChangePasswordAtLogon $false
} };
$splunkUsers='stephanie.brown','john.hall','david.evans','sarah.lee','josh.jones','joseph.smith','chirag.patel','vivek.sharma','steven.johnson','brian.wilson','rick.smith','david.green','harish.kumar','chris.h
ill','gagandeep.singh','mike.martin','mike.jackson','david.roberts','dave.jones','michael.walker','michael.allen','jeff.williams','rizwan.khan','kim.jones','juan.martinez','muhammad.usman','christopher.jones',
'adam.brown','jason.thomas','sue.smith'; 'Splunk Users','Splunk Admins' | ForEach-Object { $group=$_; $splunkUsers | ForEach-Object { Add-ADGroupMember -Identity $group -Members $_ } }
