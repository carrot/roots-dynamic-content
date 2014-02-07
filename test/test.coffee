path   = require 'path'
fs     = require 'fs'
should = require 'should'
glob   = require 'glob'
rimraf = require 'rimraf'
run    = require('child_process').exec
Roots  = require 'roots'
W      = require 'when'
nodefn = require 'when/node/function'
_path  = path.join(__dirname, 'fixtures')

should.file_exist = (path) ->
  fs.existsSync(path).should.be.ok

should.have_content = (path) ->
  fs.readFileSync(path).length.should.be.above(1)

before (done) ->
  tasks = []
  for d in glob.sync("#{_path}/*/package.json")
    p = path.dirname(d)
    if fs.existsSync(path.join(p, 'node_modules')) then continue
    console.log "installing deps for #{d}"
    tasks.push nodefn.call(run, "cd #{p}; npm install")
  W.all(tasks, -> done())

after ->
  rimraf.sync(public_dir) for public_dir in glob.sync('test/fixtures/**/public')

describe 'dynamic content', ->

  before (done) ->
    @path = path.join(_path, 'basic')
    @public = path.join(@path, 'public')
    project = new Roots(@path)
    project.compile()
      .on('error', done)
      .on 'done', =>
        @index = JSON.parse(fs.readFileSync(path.join(@public, 'index.html'), 'utf8'))
        done()

  it 'should compile all files', ->
    @index.length.should.equal(6)

    path1 = path.join(@public, 'index.html')
    should.file_exist(path1)
    should.have_content(path1)

    path2 = path.join(@public, 'posts/foo.html')
    should.file_exist(path2)
    should.have_content(path2)

    path3 = path.join(@public, 'posts/nested/nested1.html')
    should.file_exist(path3)
    should.have_content(path3)

    path4 = path.join(@public, 'posts/nested/nested2.html')
    should.file_exist(path4)
    should.have_content(path4)

    path5 = path.join(@public, 'posts/nested/double-nested/double-nested1.html')
    should.file_exist(path5)
    should.have_content(path5)

    path6 = path.join(@public, 'posts/nested/double-nested/double-nested2.html')
    should.file_exist(path6)
    should.have_content(path6)

  it 'should not write files with _render: false', ->
   fs.existsSync(path.join(@public, 'posts/other_test.html')).should.not.be.ok

  it 'should bring in compiled content', ->
    @index[1].content.should.eql "\n<p>another test</p>"

  it 'should skip content then _content: false', ->
    should.not.exist @index[0].content
    should.exist @index[2].content

  it 'should add _categories to posts', ->
    @index[0]._categories.length.should.eql 1
    @index[0]._categories[0].should.eql 'posts'
    @index[2]._categories.length.should.eql 2
    @index[2]._categories[0].should.eql 'posts'
    @index[2]._categories[1].should.eql 'nested'
    @index[4]._categories.length.should.eql 3
    @index[4]._categories[0].should.eql 'posts'
    @index[4]._categories[1].should.eql 'nested'
    @index[4]._categories[2].should.eql 'double-nested'
