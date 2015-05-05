path      = require 'path'
fs        = require 'fs'
should    = require 'should'
Roots     = require 'roots'
_         = require 'lodash'
_path     = path.join(__dirname, 'fixtures')
RootsUtil = require 'roots-util'
h         = new RootsUtil.Helpers(base: _path)
helpers   = require '../lib/helpers'

# setup, teardown, and utils

compile_fixture = (fixture_name, done) ->
  @public = path.join(fixture_name, 'public')
  h.project.compile(Roots, fixture_name).done(done)

before (done) ->
  h.project.install_dependencies('*', done)

after ->
  h.project.remove_folders('**/public')

# tests

describe 'dynamic content', ->

  before (done) ->
    compile_fixture.call @, 'basic', =>
      index_path = path.join(_path, @public, 'index.html')
      @json = JSON.parse(fs.readFileSync(index_path, 'utf8'))
      done()

  it 'should compile all files', ->
    @json.length.should.equal(7)

    path1 = path.join(@public, 'index.html')
    h.file.exists(path1).should.be.ok
    h.file.has_content(path1).should.be.ok

    path2 = path.join(@public, 'posts/foo.html')
    h.file.exists(path2).should.be.ok
    h.file.has_content(path2).should.be.ok

    path3 = path.join(@public, 'posts/nested/nested1.html')
    h.file.exists(path3).should.be.ok
    h.file.has_content(path3).should.be.ok

    path4 = path.join(@public, 'posts/nested/nested2.html')
    h.file.exists(path4).should.be.ok
    h.file.has_content(path4).should.be.ok

    path5 = path.join(@public, 'posts/nested/double-nested/double-nested1.html')
    h.file.exists(path5).should.be.ok
    h.file.has_content(path5).should.be.ok

    path6 = path.join(@public, 'posts/nested/double-nested/double-nested2.html')
    h.file.exists(path6).should.be.ok
    h.file.has_content(path6).should.be.ok

  it 'should not write files with _render: false', ->
   fs.existsSync(path.join(_path, @public, 'posts/other_test.html')).should.not.be.ok

  it 'should bring in compiled content', ->
    x = _.find(@json, {title: 'other test'})
    x.content.should.eql("\n<p>another test</p>")

  it 'should skip content then _content: false', ->
    x = _.find(@json, {title: 'foo'})
    y = y = _.find(@json, {title: 'nested 1'})

    should.not.exist(x.content)
    should.exist(y.content)

  it 'should add _categories to posts', ->
    x = _.find(@json, {title: 'foo'})
    y = _.find(@json, {title: 'nested 1'})
    z = _.find(@json, {title: 'double-nested 1'})

    x._categories.length.should.eql 1
    x._categories[0].should.eql 'posts'

    y._categories.length.should.eql 2
    y._categories[0].should.eql 'posts'
    y._categories[1].should.eql 'nested'

    z._categories.length.should.eql 3
    z._categories[0].should.eql 'posts'
    z._categories[1].should.eql 'nested'
    z._categories[2].should.eql 'double-nested'

  it 'should make all front matter available as locals', ->
    p = path.join(_path, @public, 'posts/locals_test.html')
    content = JSON.parse(fs.readFileSync(p, 'utf8'))
    content.post.wow.should.eql('amaze')

describe 'write_json', ->

  before (done) -> compile_fixture.call(@, 'write_json', -> done())

  it 'should write content to json file if specified', (done) ->
    p = path.join(@public, 'content.json')
    h.file.exists(p).should.be.ok
    h.file.contains_match(p, /another test/).should.be.ok
    h.file.contains_match(p, /_categories/).should.not.be.ok
    done()

describe 'json_keys', ->

  before (done) -> compile_fixture.call(@, 'json_keys', -> done())

  it 'should write content to json file if specified', (done) ->
    p = path.join(@public, 'content.json')
    h.file.exists(p).should.be.ok
    h.file.contains_match(p, /another test/).should.not.be.ok
    h.file.contains_match(p, /nested test/).should.be.ok
    done()

describe 'helpers', ->
  describe 'readdir', ->
    it 'should read dynamic content files in the directory', (done) ->
      helpers.readdir(path.join(_path, 'basic', 'posts')).then (res) ->
        test = _.find res, (e) -> e.title == 'foo'
        test.foo.should.eql 'bar'
        test.content.should.eql 'extends _layout\n\nblock content\n  p this is a test\n'
        done()

  describe 'readFile', ->
    it 'should read dynamic content from a single file', (done) ->
      helpers.readFile(path.join(_path, 'basic', 'posts', 'locals_test.jade'))
        .then (res) ->
          res.wow.should.eql 'amaze'
          done()

  describe 'read', ->
    it 'should read dynamic content from a string', ->
      test = "---\ntest: 'foo'\n---\nsweet content\n"
      res = helpers.read(test)
      res.test.should.eql 'foo'
      res.content.should.eql 'sweet content\n'

    it 'should read front matter from a string without content and no newline at the end with windows style line endings', ->
      test = "---\r\ntest: 'foo'\r\n---"
      res = helpers.read(test)
      res.test.should.eql 'foo'
      res.content.should.eql ''

    it 'should read dynamic content regardless of newline style', ->
      test = "---\ntest: 'foo'\n---\nsweet content\n"
      res = helpers.read(test)
      res.test.should.eql 'foo'
      res.content.should.eql 'sweet content\n'
	  
      test = "---\r\ntest: 'foo'\r\n---\r\nsweet content\r\n"
      res = helpers.read(test)
      res.test.should.eql 'foo'
      res.content.should.eql 'sweet content\r\n'
	  
      test = "---\rtest: 'foo'\r---\rsweet content\r"
      res = helpers.read(test)
      res.test.should.eql 'foo'
      res.content.should.eql 'sweet content\r'

    it "should return false if it's not formatted as dynamic content", ->
      test = "this ain't dynamic content doge"
      res = helpers.read(test).should.eql false
