dynamic_content = require '../../..'

module.exports =
  ignores: ["**/_*"]

  extensions: [dynamic_content()]

  jade:
    pretty: true
