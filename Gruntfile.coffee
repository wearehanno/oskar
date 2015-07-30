module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-release'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-env'
  grunt.loadNpmTasks('grunt-sass');
  grunt.loadNpmTasks('grunt-contrib-copy');

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
      copy:
        files: ['src/views/**/*', 'src/public/**/*']
        tasks: ['copy']

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
        dest: 'target/public/css'
        ext: '.css'
        expand: true

    coffee:
      options:
        bare: true
      classes:
        expand: true
        cwd: 'src'
        src: ['**/*.coffee']
        dest: 'target'
        ext: '.js'

    copy:
      files:
        cwd: 'src'
        src: ['views/**/*', 'public/**/*', '!public/sass/**']
        dest: 'target'
        expand: true

  grunt.registerTask 'prepublish', ['coffee', 'sass', 'copy']
