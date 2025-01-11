I build jsoncpp with Zig build system. You fetch it and use it in your Zig build system.

Doesn't support using amalgamated source. It can easily be done by exposing a function at build.zig level, but I'm lazy.
If you want an object library, get the public module "sources" and build it yourself.

Should be NOT working on OSX and some other platforms. Maybe. I don't have a Mac. Sorry. (even if I have I would be too lazy to test)

As you could possibly guess, I mean to get this into [All Your Codebase](https://github.com/allyourcodebase/). But this is not decent enough yet so...