# quarto render && hugo --config gh.yaml
quarto render && hugo
git add -A .
git commit -m "Auto-commit"
git push
