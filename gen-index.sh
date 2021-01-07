#!/bin/sh
DIR=$(pwd)
echo $DIR
for d in $(find . -not -path '*/\.*' -type d); do
	echo;echo $d;cd $d;STYLE=$(realpath --relative-to=. $DIR);STYLE="${STYLE}/style.css";echo $STYLE
	echo "<!doctype html>
<html>
	<head>
		<link rel=\"stylesheet\" href=\"$STYLE\" /link>
		<title>Index</title>
	</head>
	<body>
		<p>HTML</p>" > index.html
	for html in $(ls *html); do
		[ $html = "index.html" ] || sed -n "s/[\t]*<title>\(.*\)<\/title>/		<a href=$html>\1<\/a><br>/p" $html >> index.html
	done
	echo '		<p>PDF</p>' >> index.html
	for pdf in $(ls *pdf); do
		echo "		<a href=\"$pdf\">$pdf</a><br>" >> index.html
	done
	echo '		<p>Directories</p>' >> index.html
	for dir in $(ls -d */);do
		echo "		<a href=${dir}index.html>$dir</a>" >> index.html
	done
	echo '	</body>
</html>' >> index.html
	cat index.html
done

