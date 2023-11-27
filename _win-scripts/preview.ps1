#$env:JEKYLL_GITHUB_TOKEN = "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"
# This is so annoying lol
.\clean_html.ps1
#(Get-Content c:\temp\test.txt).replace('[MYID]', 'MyValue') | Set-Content c:\temp\test.txt
#python fix_folding.py
bundle exec jekyll serve --livereload
