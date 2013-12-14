pkgJson = require('./package.json')

module.exports = (grunt) ->

  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-coffee')
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

    watch:
      files: ['src/*.coffee']
      tasks: ['default']
  )

  grunt.registerTask('default', ['clean', 'coffee'])
