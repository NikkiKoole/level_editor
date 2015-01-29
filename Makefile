serve:
	http-server .
watch:	
	watchify -v -t coffeeify --extension=".coffee" source/main.coffee -o bundle.js -d
test:
	jasmine-node --coffee spec
