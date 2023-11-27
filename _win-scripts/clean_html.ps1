Get-ChildItem -Path "./_posts/" -Filter "*.md" |
Foreach-Object {
    (Get-Content $_.FullName).replace("<summary>", "<summary markdown=`"span`">").replace("<div class=`"table-wrapper`" markdown=`"block`">", "").replace("</details>", "</details>`r`n`r`n<div class=`"table-wrapper`" markdown=`"block`">`r`n`r`n") | Set-Content $_.FullName

    #Write-Output $content
}
