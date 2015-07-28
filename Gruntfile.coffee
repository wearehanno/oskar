module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-release'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-env'
  grunt.loadNpmTasks('grunt-sass');

  grunt.initConfig
    watch:
      coffee:
        files: [
          '**/*.coffee'   # Watch everything
          '!node_modules' # ...except dependencies
        ]
        tasks: ['coffee']
      libsass:
        files: '**/*.scss'
        tasks: ['sass']

    shell:
      test:
        command: 'npm test'
        options:
          stdout: true
          stderr: true
      run:
        command: 'node src/index'
        options:
          stdout: true

    sass:
      files:
        cwd: 'src/public/sass'
        src: ['**/*.scss']
        dest: 'src/public/css'
        ext: '.css'
        expand: true
    coffee:
      options:
        bare: true
      index:
        files:
          'src/oscar.js': 'src/oscar.coffee'
      classes:
        expand: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'src'
        ext: '.js'
      modules:
        expand: true
        cwd: 'src/modules'
        src: ['*.coffee']
        dest: 'src/modules'
        ext: '.js'
      helper:
        expand: true
        cwd: 'src/helper'
        src: ['*.coffee']
        dest: 'src/helper'
        ext: '.js'
      content:
        expand: true
        cwd: 'src/content'
        src: ['*.coffee']
        dest: 'src/content'
        ext: '.js'

  grunt.registerTask 'prepublish', ['coffee']
