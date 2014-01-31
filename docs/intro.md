Roots Dynamic Content
=====================

Dynamic content is an officially maintained extension of roots that adds a large chunk of additional functionality, allowing users to manage static content in a dyamic and powerful fashion.

### Getting Started

Let's say you have a little blog you want posts for. But you also want an index page that lists all your posts. With a normal static compiler, there is no way to achieve this. Dynamic content makes things like this possible.

Following the blog example, let's walk through how to make this happen. First, make a folder called 'posts', and drop your first post in there - let's make it a jade file. Now, you can add some [front matter](#) to the top of the file to make it dynamic. For example:

```jade
---
title: 'Hello world!'
date: 1/2/2014
---

:markdown
  This is my **first blog post** yaaaa!
```

Roots will handle files with front matter differently. First, the file's front matter and contents will be made available on a local called `site` that's exposed in every other non-dynamic template. It will be scoped under the folder that it's in. For example, to pull it in to a blog index:

```jade
each post in site.posts
  a.post
    h2= post.title
    date= post.date
    != post.content
```

So a couple things here. First, we can see how all dynamic files are scoped onto `site` under their folder name, and that we have access to the front matter variables (`title` and `date`), as well as one special property, `content`, which is the compiled content of the file (minus the front matter). If you add another post to the `posts` folder, it will also show up in the index.

There's nothing special about the `posts` name, you can make a folder with any other name, put dynamic content in it, and it will be put on `sites` so you can iterate through it anywhere else.

### Deep Nesting

So let's say you want to get a little more granular with your blog posts, and you have a couple different categories that you want: `news`, `hires`, and `doge`. You can just make folders for each of these categories and sort your blog posts into them. So your folder structure might look like this:

```
example-project
˾ posts
  ˾ news
    ˾ news_post.jade
  ˾ hires
    ˾ hires_post.jade
  ˾ doge
    ˾ wow.jade
```

So now we can access these posts in two different ways. First, if you just want to grab **all posts nested under `posts`**, you can do something like this:

```jade
each post in site.posts.all()
  a.post
    h2= post.title
    date= post.date
    .category= post._categories[-1]
    != post.content
```

Two new things here -- first, calling the `all()` function on any category will recursively grab all dynamic content nested under it and return a flattened array. Second, you can see that each post also gets a special property called `_categories`, which is an array of the folder names that it's nested under, in order. Here, we can list the post's category by just grabbing the last index of this array.

Second, we can explicitly drill down to each category. For example, if you wanted to display each category in a different place, you could do something like this:

```jade
#news
  each post in site.posts.news
    ...

#hires
  each post in site.posts.hires
    ...

#doge
  each post in site.posts.doge
    ...
```

If you are nesting any deeper, you also have an `all()` function on each of these categories. Everything is handled in a recursive fashion, so you can get as crazy as you want with this (although honestly I wouldn't recommend more than 2 levels deep).

If you are sharp, you may have noticed that although we don't have "single post views" at the moment, the post contents (minus front matter) and still being written to public under their respective folders. To prevent these writes, we can add a special key to the front matter as such:

```jade
---
title: 'Hello world!'
date: 1/2/2014
_render: false
---

:markdown
  This is my **first blog post** yaaaa!
```

This will prevent the file from rendering and writing, since we don't need a single view here and are simply using the `post.content` property to render out the content in the index.

### Single Post Views

Ok, so this is looking good so far, but what happens when you want to click into a blog post rather than just displaying it on the index? For this, we need a url and a layout. We can solve this quickly using jade layouts and the special `post.url` property. In the body of the file, rather than the single markdown line, we'll also include the `extends` and `block` directives, remove the `content` print on the index page, and add a link to the title pointing to `post.url`. Let's take a look, first at the modified post (assuming you have set up a layout already):

```jade
---
title: 'Hello world!'
date: 1/2/2014
_content: false
---

extends single_post_layout

block content
  :markdown
    This is my **first blog post** yaaaa!
```

And updates to the index page:

```jade
each post in site.posts.all()
  a.post
    h2: a(href=post._url) post.title
    date= post.date
```

Note that in the index page, we have removed `post.content`, as the content is going on it's own page, and would now also be surrounded by the layout. If you want a "preview" or "snippet" of the blog post, you should add that directly to the front matter. Taking a slice of the markup is usually a bad idea anyway, as you can slice in the middle of an open tag and it will mess up the rest of your page (for example, if you cut your snippet off in the middle of a bold tag before it closes, the rest of your page will be bold). For blog post snippets, you want to go with just plain text, which is better suited to the front matter than the body of the file.

Now when we hit the url, we'll see the post rendered into a layout as it should be. You'll see the special property `post._url` as mentioned earlier, which simply prints a path to the post, including the deep-nesting if present. You might have also noticed the special `_content` key being set to false in the post file. This will just remove `post.content`, since we are no longer using it, and the full post contents with the full layout times a bunch of posts can be a very lengthy unused value. While you certainly can get away with not including this special key, if you are not planning on using `post.contents` on your index page, it's recommended that you just cut it for cleanliness and speed.
