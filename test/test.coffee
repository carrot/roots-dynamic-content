should = require 'should'

describe 'basic', ->

  it 'should work', (done) ->
    project = new Roots(path.join(__dirname, 'fixtures/extensions/dynamic'))
    project.compile()
      .on('error', done)
      .on('done', done)
