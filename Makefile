REPORTER = list

test:
	@./node_modules/.bin/mocha tests/*.coffee --reporter $(REPORTER) --compilers coffee:coffee-script

cov:
	@./node_modules/.bin/istanbul cover ./node_modules/.bin/_mocha tests/*.coffee --root build/ -x diff_match_patch.js -- --compilers coffee:coffee-script
