path = require 'path'
fs = require 'fs'
_ = require 'lodash'
yaml = require 'js-yaml'
W = require 'when'

class DynamicContent

  fs: ->
    category: 'dynamic'
    extract: true
    ordered: true
    detect: detect_fn

  compile_hooks: ->
    before_pass: before_hook.bind(@)
    after_file: after_hook.bind(@)

  # @api private
  
  ###*
   * Read the first three bytes of each file, if they are '---', assume
   * that we're working with dynamic content.
   * @param  {String} file - path to file
   * @return {Boolean}       promise returning true or false
  ###
  detect_fn = (file) ->
    deferred = W.defer()
    res = false

    fs.createReadStream(file.path, { encoding: 'utf-8', start: 0, end: 3 })
      .on('error', deferred.reject)
      .on('end', -> deferred.resolve(res))
      .on 'data', (data) ->
        if data.split('\n')[0] == "---" then res = true

    return deferred.promise

  ###*
   * For dynamic files before the last compile pass:
   * - remove the front matter, parse into an object
   * - add the object to the locals, nesting as deep as the folder it's in
   * - add an "all" utility function to each level
   * @param  {Object} ctx - roots context
  ###
  before_hook = (ctx) ->
    # if category is dynamic and last pass
    if ctx.file.category == @fs().category && ctx.index == ctx.file.adapters.length

      # pull the front matter, remove it from the content
      front_matter_str = ctx.content.match(/^---\s*\n([\s\S]*?)\n?---\s*\n?/)
      front_matter = yaml.safeLoad(front_matter_str[1])
      ctx.content = ctx.content.replace(front_matter_str[0], '')

      # get categories and per-compile locals, add site key and make sure it's defined
      folders = path.dirname(ctx.file.path).replace(ctx.file.roots.root, '').slice(1).split(path.sep)
      locals = ctx.file.compile_options.site ?= {}
      file_locals = ctx.file.file_options

      # add special keys for url and categories
      front_matter._categories = folders
      front_matter._url = ctx.file.roots.config.out(ctx.file.path, ctx.adapter.output).replace(ctx.file.roots.config.output_path(), '')

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
   * After a file in the category has been compiled:
   * - grab the content and add it to the locals object
   * - if _render: false is in the locals don't write it
   * @param  {Object} ctx - roots context
   * @return {Boolean}
  ###
  after_hook = (ctx) ->
    if ctx.category != @fs().category then return true
    locals = ctx.file_options.post

    # put rendered content into the locals unless _content key is false
    locals.content = ctx.content unless locals._content == false

    # if _render key is false, return false to not write the file
    if locals._render == false then false else true

  ###*
   * returns an array of all the dynamic conteent object in the folder
   * it was called on, as well as every folder nested under it, flattened
   * into a single array.
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

module.exports = DynamicContent
