DEPRECATED
===
This library is no longer being maintained. Please take a look at [Rich Text OT Type](https://github.com/ottypes/rich-text) for a reasonable alternative.

Tandem Core
===

This repository is also both a Rails gem and a Node.js module.

[![Build Status](https://secure.travis-ci.org/tandem/tandem-core.png?branch=master)](http://travis-ci.org/tandem/tandem-core)


Project Organization
---

### Top level files/directories

The tandem source code is in the **src** folder. Tests are in the **tests** folder.

All other files/directories are just supporting npm/bundler, build, or documentation files.

    build - javascript output
    lib - bundler
    src - source code
    tests - tests written for Mocha on node.js
    vendor/assets/javascripts/* - symlinks to src with .module added before extension
    delta.js - entry point for tandem/scribe coffeeify
    index.js - npm
    package.json - npm
    tandem-core-rails.gemspec - bundler


### Version numbers

Until we write a script, version numbers will have to be updated in the following files:

- lib/tandem-core-rails/version.rb
- package.json


### Tests

We use the mocha testing framework. To run:

    make test

To run code coverage tests:

    make cov

Visit coverage/lcov-report/index.html in your browser to see the output.

## License

Copyright (c) 2012, Salesforce.com, Inc.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  Redistributions in binary
form must reproduce the above copyright notice, this list of conditions and
the following disclaimer in the documentation and/or other materials provided
with the distribution.  Neither the name of Salesforce.com nor the names of
its contributors may be used to endorse or promote products derived from this
software without specific prior written permission.
