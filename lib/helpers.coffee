fs     = require 'fs'
path   = require 'path'
W      = require 'when'
nodefn = require 'when/node'
os     = require 'os'
yaml   = require 'js-yaml'
_      = require 'lodash'

###*
 * Read the first three bytes of each file, if they are '---', assume
 * that we're working with dynamic content.
 *
 * @private
 *
 * @param  {File} file - vinyl-wrapped file instance
 * @return {Boolean} promise returning true or false
###

detect = (path) ->
  deferred = W.defer()
  res = false

  fs.createReadStream(path, encoding: 'utf-8', start: 0, end: 3)
    .on('error', deferred.reject)
    .on('end', -> deferred.resolve(res))
    .on 'data', (data) ->
      if data.split(os.EOL.substring(0,1))[0] is '---' then res = true

  return deferred.promise

read = (str) ->
  br = "\\#{os.EOL}" # cross-platform newline
  regex = new RegExp(///^---\s*#{br}([\s\S]*?)#{br}?---\s*#{br}?///)
  front_matter_str = str.match(regex)
  data = yaml.safeLoad(front_matter_str[1])
  data.content = str.replace(front_matter_str[0], '')
  return data

readFile = (path) ->
  nodefn.call(fs.stat, path)
    .then (res) ->
      if res.isDirectory() then return false
      detect(path).then (res) ->
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
