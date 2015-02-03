dynamic_content = require '../../..'

module.exports =
  ignores: ["**/_*"]

  extensions: [dynamic_content(write: 'content.json')]

  jade:
    pretty: true
