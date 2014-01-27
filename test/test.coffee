path = require 'path'
should = require 'should'
glob = require 'glob'
rimraf = require 'rimraf'
Roots = require 'roots'

describe 'basic', ->

  it 'should work', (done) ->
    project = new Roots(path.join(__dirname, 'fixtures/basic'))
    project.compile()
      .on('error', done)
      .on('done', done)

after ->
  rimraf.sync(public_dir) for public_dir in glob.sync('test/fixtures/**/public')
