bundle exec jekyll build --config _gh_config.yml
bundle exec jekyll build --config _gu_config.yml
bundle exec jekyll build --config _su_config.yml
git add -A .
git commit -m "Auto-commit"
git push
