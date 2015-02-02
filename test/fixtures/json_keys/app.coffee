dynamic_content = require '../../..'

module.exports =
  ignores: ["**/_*"]

  extensions: [dynamic_content(write: { 'content.json': 'posts/nested' })]

  jade:
    pretty: true
