path = require 'path'
fs   = require 'fs'
_    = require 'lodash'
helpers = require './helpers'

module.exports = (opts = {}) ->

  class DynamicContent
    constructor: ->
      @category = 'dynamic'
      @all_content = []

    fs: ->
      extract: true
      ordered: true
      detect: (f) -> helpers.detect_file(f.path)

    compile_hooks: ->
      before_pass: before_hook.bind(@)
      after_file: after_hook.bind(@)
      write: write_hook.bind(@)

    category_hooks: ->
      after: after_category.bind(@)

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
      # if last pass
      if ctx.index is ctx.file.adapters.length
        f = ctx.file
        roots = f.roots

        data         = helpers.read(ctx.content)
        front_matter = _.omit(data, 'content')
        ctx.content  = data.content

        # get categories and per-compile locals, add or define site key
        folders = path.dirname(f.file.relative).split(path.sep)
        locals = f.compile_options.site ?= {}
        file_locals = f.file_options

        # add special keys for url and categories
        front_matter._categories = folders
        front_matter._url = roots.config.out(f.file, ctx.adapter.output)
                              .replace(roots.config.output_path(), '')
                              .replace(new RegExp('\\' + path.sep, 'g'), '/')

        # deep nested dynamic content
        # - make sure the backtraced path to a deep-nested folder exists
        # - push the front matter to the folder name array/object
        # - add special 'all' function to the array/object
        # - save pointer to the front matter obj under file-specific post local
        for f, i in folders
          locals[f] ?= []
          locals = locals[f]
          if i is folders.length - 1
            locals.push(front_matter)
            @all_content.push(front_matter)
            locals.all = all_fn
            file_locals.post = locals[locals.length - 1]

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
      locals.content = ctx.content unless locals._content is false

    ###*
     * After the category has finished, if the user has chosen to have all
     * dynamic content written as json, make that happen. This can only happen
     * if a `write` option has been provided with an `output` key. Also can
     * optionally contain `flattened` and `keys` keys, which reformat or filter
     * the data in a certain way.
     *
     * @param  {Object} ctx - roots context
    ###
    after_category = (ctx) ->
      opt = opts.write

      if opt
        content = reformat(@all_content)
        if typeof opt is 'string' then return write_json(ctx, opt, content)
        write_json(ctx, k, filter(content, v)) for k, v of opt

    ###*
     * If a dynamic file has `_render` set to false in the locals, don't write
     * the file. Otherwise write as usual.
     *
     * @param  {Object} ctx - roots context
     * @return {Boolean} whether or not to write the file as usual
    ###

    write_hook = (ctx) ->
      ctx.file_options.post._render isnt false

    ###*
     * Returns an array of all the dynamic content object in the folder
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

module.exports.Helpers = helpers

# private

reformat = (data) ->
  output = {}
  for item in data
    pointer = output
    for level in item._categories
      pointer[level] ?= {}
      pointer[level]['items'] ?= []
      pointer = pointer[level]
    delete item._categories
    pointer.items.push(item)
  return output

filter = (data, keys) ->
  keys = keys.split('/')
  pointer = data
  for key in keys
    pointer = pointer[key]
  return pointer

write_json = (ctx, relative_path, content) ->
  destination = path.join(ctx.roots.config.output_path(), relative_path)
  fs.writeFileSync(destination, JSON.stringify(content))
