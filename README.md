Roots Dynamic Content
=====================

[![npm](https://badge.fury.io/js/dynamic-content.png)](http://badge.fury.io/js/dynamic-content) [![tests](https://travis-ci.org/carrot/roots-dynamic-content.png?branch=master)](https://travis-ci.org/carrot/roots-dynamic-content) [![dependencies](https://david-dm.org/carrot/roots-dynamic-content.png?theme=shields.io)](https://david-dm.org/carrot/roots-dynamic-content)

Dynamic content functionality for roots

> **Note:** This project is in early development, and versioning is a little different. [Read this](http://markup.im/#q4_cRZ1Q) for more details.

### Installation

- make sure you are in your roots project directory
- `npm install dynamic-content --save`
- modify your `app.coffee` file to include the extension, as such
  
  ```coffee
  DynamicContent = require('dynamic-content')

  module.exports =
    extensions: [new DynamicContent]
    
    # everything else...
  ```

### Usage

Please see the [documentation](docs) for an overview of the functionality.

### License & Contributing

- Details on the license [can be found here](LICENSE.md)
- Details on running tests and contributing [can be found here](contributing.md)
