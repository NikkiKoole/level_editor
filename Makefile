serve:
	node node_modules/http-server/bin/http-server .
watch:	
	node ./node_modules/watchify/bin/cmd.js -v -t coffeeify --extension=".coffee" source/main.coffee -o bundle.js
debug:	
	node ./node_modules/watchify/bin/cmd.js -v -t coffeeify --extension=".coffee" source/main.coffee -o bundle.js -d

