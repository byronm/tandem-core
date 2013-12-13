pkgJson = require('./package.json')

module.exports = (grunt) ->

  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.initConfig(
    meta:
      version: pkgJson.version

    clean: ['build']

    coffee:
      src:
        expand: true
        dest: 'build/'
        flatten: true
        src: ['src/*.coffee']
        ext: '.js'

    concat:
      options:
        banner: 
          '/*! Tandem Core - v<%= meta.version %> - <%= grunt.template.today("yyyy-mm-dd") %>\n' +
          ' *  https://www.stypi.com/\n' +
          ' *  Copyright (c) <%= grunt.template.today("yyyy") %>\n' +
          ' *  Jason Chen, Salesforce.com\n' +
          ' *  Byron Milligan, Salesforce.com\n' + 
          ' */\n\n'
      src:
        expand: true
        dest: 'build/'
        flatten: true
        src: ['build/*.js']
        ext: '.js'

    watch:
      files: ['src/*.coffee']
      tasks: ['default']
  )

  grunt.registerTask('default', ['clean', 'coffee', 'concat'])
