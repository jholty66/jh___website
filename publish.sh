cd $(dirname "$0")
pwd
./gen-index.sh
git add *html
git commit -m $(date +%Y-%m-%d)
git diff *html
git push
