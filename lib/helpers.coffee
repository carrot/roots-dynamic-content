fs     = require 'fs'
path   = require 'path'
W      = require 'when'
nodefn = require 'when/node'
yaml   = require 'js-yaml'
_      = require 'lodash'

BR = "(?:\\\r\\\n|\\\n|\\\r)" # cross-platform newline
LINEBREAK_REGEXP = new RegExp(BR)
FRONTMATTER_REGEXP = new RegExp(///^---\s*#{BR}([\s\S]*?)#{BR}?---\s*#{BR}?///)

###*
 * Read the first three bytes of each file, if they are '---', assume
 * that we're working with dynamic content.
 *
 * @private
 *
 * @param  {File} file - vinyl-wrapped file instance
 * @return {Boolean} promise returning true or false
###

detect = (str) ->
  if str.split(LINEBREAK_REGEXP)[0] == '---' then true else false

detect_file = (path) ->
  deferred = W.defer()
  res = false

  fs.createReadStream(path, encoding: 'utf-8', start: 0, end: 3)
    .on('error', deferred.reject)
    .on('end', -> deferred.resolve(res))
    .on 'data', (data) -> if detect(data) then res = true

  return deferred.promise

read = (str) ->
  if not detect(str) then return false
  front_matter_str = str.match(FRONTMATTER_REGEXP)
  data = yaml.safeLoad(front_matter_str[1])
  data.content = str.replace(front_matter_str[0], '')
  return data

readFile = (path) ->
  nodefn.call(fs.stat, path)
    .then (res) ->
      if res.isDirectory() then return false
      detect_file(path).then (res) ->
        if not res then return false
        nodefn.call(fs.readFile, path, 'utf8').then(read)

readdir = (dir) ->
  nodefn.call(fs.readdir, dir)
    .then (paths) -> W.map(paths, (p) -> readFile(path.join(dir, p)))
    .then _.compact

module.exports =
  read: read
  readFile: readFile
  readdir: readdir
  detect_file: detect_file
