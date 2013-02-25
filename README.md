# rendactive.js

Experimental reactive template rendering with Bacon.js + Meteor Spark

Bacon.js: https://github.com/raimohanska/bacon.js
Spark: https://github.com/meteor/meteor/wiki/Spark

This is just a proof-of-concept so far -- it's not recommended for real use. The API is probably too limited/sucky for anything serious.

# Examples:

## flickr instant search with pagination:
Demo: http://roboteddy.github.com/rendactive.js/examples/flickr/index.html

Source: https://github.com/RoboTeddy/rendactive.js/blob/master/examples/flickr/flickr.coffee

## todo (in the style of todomvc.com):
Demo: http://roboteddy.github.com/rendactive.js/examples/todo/index.html

Source: https://github.com/RoboTeddy/rendactive.js/blob/master/examples/todo/todo.coffee

Notes:
======

An advantage of this simple implementation is that it doesn't care which template engine you use. The first argument to rendactive is just any function that takes a hash of data and returns a string of html.

A disadvantage of this simple implementation is that DOM recomputes aren't as granular as they could be. The DOM fragment returned by a given call to rendactive is fully redrawn whenever any of the properties passed in change. This means that if your application had one rendactive call that rendered the entire page, it might end up doing too much work on each property change. A DOM-heavy application using this version of rendactive may need to split up its ui into multiple rendactive calls, each of which depends on a smaller number of properties. This might be cumbersome for a lot of applications, especially since it means that reactive templates can't efficiently include reactive sub-templates.

A solution is to add/wrap features of the template engine such that smaller reactive contexts are created automatically whenever a template is included from a different template (or created expressly via a template directive). This is what Meteor does. They extend/hack Handlebars to make it happen (they build an AST of handlebars templates in order to explicitly label pathways through it).

If we end up wanting this functionality, we could either pull in Meteor's handlebar extensions, or perhaps use https://github.com/bminer/node-blade, which has Spark tie-ins. I'm wary of both options -- they both involve template preprocessing, Blade looks a bit immature, and Meteor's hacked handlebars might be a moving target. So, I don't see any good short-term options. On the plus side, I Spark itself seems solid.

Sidenote: if you pass a property to a template with rendactive, the template will recompute on property changes regardless of whether or not the template actually uses the value rendered by that property. For now, this isn't that bad, since it's pretty easy to only pass in properties that a given template actually depends on. If we end up tying rendactive in with specific template engine(s), this wouldn't be too hard to fix.