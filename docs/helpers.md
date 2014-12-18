Dynamic Content Helper Functions
================================

You can load a set of helper functions from the extension if you want to read dynamic content from a directory, file, or string outside of the Roots build process. This is useful if you need to load dynamic content data and migrate it to another data format.

### Getting Started

Require the helpers module from the extension:

```coffee
helpers = require('dynamic-content').Helpers
```

> **Note:** These helpers use a couple bits of logic from the main extension to parse dynamic content files. **However**, these helpers do not add additional features provided through roots such as the `_url` key, nor is any content below the front matter compiled.

### helpers.readdir

Takes a directory path string argument to the target directory. Returns a promise for an array of dynamic content objects.

```coffee
helpers.readdir('project/blog_posts')
  .then (res) -> console.log(res)
```

> **Note:** This function is non-recursive and does not nest content like roots would.

### helpers.readFile

Takes a file path string argument. Returns a promise for an object representing the file's dynamic content. Returns `false` if the file is detected to not be dynamic content.

```coffee
helpers.readFile('project/blog_posts/welcome.jade')
  .then (res) -> console.log(res)
```

### helpers.read

Takes a string argument. This does not return a promise, it returns an object for the dynamic content, or `false` if the string is not formatted as dynamic content.
