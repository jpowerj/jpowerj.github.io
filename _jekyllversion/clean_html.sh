#!/bin/bash
# NOTE : Quote it else use array to avoid problems #
FILES="./_posts/*.md"
for f in $FILES
do
  echo "Processing $f..."
  # take action on each file. $f store current file name
  sed -i '' 's|<summary>|<summary markdown=\"span\">|g' "$f";
  sed -i '' 's|<div class=\"table-wrapper\" markdown=\"block\">||g' "$f";
  sed -i '' 's|</details>|</details>\r\n\r\n<div class=\"table-wrapper\" markdown=\"block\">|g' "$f";
done
