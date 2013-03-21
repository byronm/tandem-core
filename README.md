Tandem Core
===

This repository is also both a Rails gem and a Node.js module.


Project Organization
---

### Top level files/directories

The tandem source code is in the **src** folder. Tests are in the **tests** folder.

All other files/directories are just supporting npm/bundler, build, or documentation files.

    lib - bundler
    src - source code
    tests - tests written for Mocha on node.js
    vendor/assets/javascripts/* - symlinks to src with .module added before extension
    index.js - npm
    package.json - npm
    tandem.gemspec - bundler
    

### Version numbers

Until we write a script, version numbers will have to be updated in the following files:

- lib/tandem-core-rails/version.rb
- package.json


### Tests

We use the mocha testing framework. To run:

    make test

To run code coverage tests, install https://github.com/visionmedia/node-jscoverage and run

    make coverage

Visit coverage.html in your browser to see the output.
