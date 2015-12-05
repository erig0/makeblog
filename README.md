## makeblog

A simple static blog generator written in BSD make.

#### Why?

* I had grown tired of overly complicated and fragile blog engines.
  * Wanted to type `make` and have it "just work"
* Wanted to write posts locally in VIM instead of via a web browser.
* Didn't want dependencies of other static blog generators; ruby, python, etc.
* Wanted to track posts and history in SCM; i.e. git.

#### Features

* Basic blog
  * Markdown
  * history/archive
  * drafts
  * RSS feed
* Media
  * image thumbnailing
  * video conversion to HTML5 (h264, ogg vorbis)
* templates
* tiny, ~400 LOC makefile

#### Disclaimer

I threw this to the public as an example. If there is interest I can polish and clean it up.
