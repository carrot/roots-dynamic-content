DynamicContent = require '../../..'

module.exports =
  ignores: ["**/_*"]

  extensions: [new DynamicContent]

  jade:
    pretty: true
