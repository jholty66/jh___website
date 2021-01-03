cd $(dirname "$0")
pwd
./gen-index.sh
git add *html *pdf
git commit -m $(date +%Y-%m-%d)--sync-website
git diff *html
git push
