path = require 'path'
fs = require 'fs'
_ = require 'lodash'
yaml = require 'js-yaml'
W = require 'when'
os = require 'os'

module.exports = ->

  class DynamicContent

    constructor: ->
      @category = 'dynamic'

    fs: ->
      extract: true
      ordered: true
      detect: detect_fn

    compile_hooks: ->
      before_pass: before_hook.bind(@)
      after_file: after_hook.bind(@)
      write: write_hook.bind(@)

    ###*
     * Read the first three bytes of each file, if they are '---', assume
     * that we're working with dynamic content.
     *
     * @private
     *
     * @param  {File} file - vinyl-wrapped file instance
     * @return {Boolean} promise returning true or false
    ###

    detect_fn = (file) ->
      deferred = W.defer()
      res = false

      fs.createReadStream(file.path, { encoding: 'utf-8', start: 0, end: 3 })
        .on('error', deferred.reject)
        .on('end', -> deferred.resolve(res))
        .on 'data', (data) ->
          if data.split(os.EOL.substring(0,1))[0] == "---" then res = true

      return deferred.promise

    ###*
     * For dynamic files before the last compile pass:
     * - remove the front matter, parse into an object
     * - add the object to the locals, nesting as deep as the folder it's in
     * - add an "all" utility function to each level
     *
     * @private
     *
     * @param  {Object} ctx - roots context
    ###

    before_hook = (ctx) ->
      # if  last pass
      if ctx.index == ctx.file.adapters.length
        f = ctx.file
        roots = f.roots

        # pull the front matter, remove it from the content
        br = "\\#{os.EOL}" # cross-platform newline
        regex = new RegExp("^---\s*#{br}([\\s\\S]*?)#{br}?---\s*#{br}?")
        front_matter_str = ctx.content.match(regex)
        front_matter = yaml.safeLoad(front_matter_str[1])
        ctx.content = ctx.content.replace(front_matter_str[0], '')

        # get categories and per-compile locals, add site key and make sure it's defined
        folders = path.dirname(f.file.relative).split(path.sep)
        locals = f.compile_options.site ?= {}
        file_locals = f.file_options

        # add special keys for url and categories
        front_matter._categories = folders
        front_matter._url = roots.config.out(f.file, ctx.adapter.output).replace(roots.config.output_path(), '')

        # deep nested dynamic content
        # - make sure the backtraced path to a deep-nested folder exists
        # - push the front matter to the folder name array/object
        # - add special 'all' function to the array/object
        # - save a pointer to the front matter object under file-specific `post` local
        for f, i in folders
          locals[f] ?= []
          locals = locals[f]
          if i == folders.length-1
            locals.push(front_matter)
            locals.all = all_fn
            file_locals.post = locals[locals.length-1]

    ###*
     * After a file in the category has been compiled, grabs the content and
     * adds it to the locals object unless _content key is false
     *
     * @private
     *
     * @param  {Object} ctx - roots context
     * @return {Boolean}
    ###

    after_hook = (ctx) ->
      locals = ctx.file_options.post
      locals.content = ctx.content unless locals._content == false

    ###*
     * If a dynamic file has `_render` set to false in the locals, don't write
     * the file. Otherwise write as usual.
     *
     * @param  {Object} ctx - roots context
     * @return {Boolean} whether or not to write the file as usual
    ###

    write_hook = (ctx) ->
      !(ctx.file_options.post._render == false)

    ###*
     * Returns an array of all the dynamic conteent object in the folder
     * it was called on, as well as every folder nested under it, flattened
     * into a single array.
     *
     * @private
     *
     * @return {Array} Array of dynamic content objects
    ###

    all_fn = ->
      values = []
      recurse = (obj) ->
        for o in Object.keys(obj)
          if not isNaN(parseInt(o)) then values.push(obj[o]); continue
          recurse(obj[o])
      recurse(this)
      values
