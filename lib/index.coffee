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
  
  detect_fn = (file) ->
    deferred = W.defer()
    res = false

    fs.createReadStream(file, { encoding: 'utf-8', start: 0, end: 3 })
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
    if ctx.file.category == @fs().category && ctx.index == ctx.file.adapters.length
      front_matter_str = ctx.content.match(/^---\s*\n([\s\S]*?)\n?---\s*\n?/)
      front_matter = yaml.safeLoad(front_matter_str[1])
      ctx.content = ctx.content.replace(front_matter_str[0], '')

      folders = path.dirname(ctx.file.path).replace(ctx.file.roots.root, '').slice(1).split(path.sep)
      locals = ctx.file.options

      # add categories hidden key
      front_matter._categories = folders

      # deep nested dynamic content
      for f, i in folders
        locals[f] ?= []
        locals = locals[f]
        if i == folders.length-1
          locals.push(front_matter)
          locals.all = all_fn
          ctx.file.pointer = locals[locals.length-1]

  ###*
   * After a file in the category has been compiled:
   * - grab the content and add it to the locals object
   * - if _render: false is in the locals don't write it
   * @param  {Object} ctx - roots context
   * @return {Boolean}
  ###
  after_hook = (ctx) ->
    if ctx.category == @fs().category
      ctx.pointer.content = ctx.content
      if ctx.options._render == false then false else true
    else
      true

  ###*
   * returns a folder's content and the content of all nested
   * folders, flattened out
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
