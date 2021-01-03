#!/bin/sh
mv index.html index.html.bak
ls *html
echo '<!doctype html>
<html>
	<head>
		<link rel="stylesheet" href="jh___.css" /link>
		<title>Index</title>
	</head>
	<body>' > index.html

for file in $(ls *html)
do
[ $file = "index.html" ] || sed -n "s/[\t]*<title>\(.*\)<\/title>/		<a href=$file>\1<\/a>/Ip" $file >> index.html
done
echo '	</body>
</html>' >> index.html
cat index.html
