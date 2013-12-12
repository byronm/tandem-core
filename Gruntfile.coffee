pkgJson = require('./package.json')

module.exports = (grunt) ->

  grunt.loadNpmTasks('grunt-browserify')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.initConfig(
    meta:
      version: pkgJson.version

    coffee:
      tests:
        expand: true
        dest: 'build/'
        src: ['tests/client/*.coffee']
        ext: '.js'

    browserify:
      options:
        extensions: ['.js', '.coffee']
        standalone: 'tandem-core'
        transform: ['coffeeify']
      tandem_core:
        files: [{ dest: 'build/tandem-core.js', src: ['browser.js'] }]

    concat:
      options:
        banner: 
          '/*! Tandem Core - v<%= meta.version %> - <%= grunt.template.today("yyyy-mm-dd") %>\n' +
          ' *  https://www.stypi.com/\n' +
          ' *  Copyright (c) <%= grunt.template.today("yyyy") %>\n' +
          ' *  Jason Chen, Salesforce.com\n' +
          ' *  Byron Milligan, Salesforce.com\n' + 
          ' */\n\n'
      'build/tandem-core.js': ['build/tandem-core.js']

    watch:
      files: ['src/*.coffee']
      tasks: ['default']
  )

  grunt.registerTask('default', ['coffee', 'browserify', 'concat'])
