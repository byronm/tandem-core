REPORTER = list

test:
	@./node_modules/.bin/mocha tests/*.coffee --reporter $(REPORTER) --compilers coffee:coffee-script

cov:
	@rm -rf src-js test-js
	@./node_modules/.bin/coffee -c -o src-js src
	@cp src/*.js src-js/
	@./node_modules/.bin/coffee -c -o test-js tests
	@TANDEM_COV=1 ./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha test-js/*.js --root src-js -x diff_match_patch.js
	@rm -rf src-js test-js
