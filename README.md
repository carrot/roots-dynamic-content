Roots Dynamic Content
=====================

[![npm](http://img.shields.io/npm/v/dynamic-content.svg?style=flat)](http://badge.fury.io/js/dynamic-content) [![tests](http://img.shields.io/travis/carrot/roots-dynamic-content/master.svg?style=flat)](https://travis-ci.org/carrot/roots-dynamic-content) [![dependencies](http://img.shields.io/gemnasium/carrot/roots-dynamic-content.svg?style=flat)](https://david-dm.org/carrot/roots-dynamic-content)

Dynamic content functionality for roots

> **Note:** This project is in early development, and versioning is a little different. [Read this](http://markup.im/#q4_cRZ1Q) for more details.

### Installation

- make sure you are in your roots project directory
- `npm i dynamic-content -S`
- modify your `app.coffee` file to include the extension, as such

  ```coffee
  dynamic_content = require 'dynamic-content'

  module.exports =
    extensions: [dynamic_content()]

    # everything else...
  ```

### Usage

Please see the [documentation](docs) for an overview of the functionality.

### License & Contributing

- Details on the license [can be found here](LICENSE.md)
- Details on running tests and contributing [can be found here](contributing.md)
