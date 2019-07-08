# Background

I started using Gollum wiki with Gitlab. For whatever reason, I like the in-browser text editor used by Gollum, so I decided to pull it out for use with any app rather than just Gollum. That repo is [here](https://github.com/bachmeil/gollum-editor).

This repo holds an example demonstrating its use with a CGI program created using Adam Ruppe's cgi.d. I thought it might have value to others as an example of cgi.d usage or as an example of how to add the editor to a D program.

# filegen.d

As is common in Javascript projects, Gollum's editor has a ton of dependencies (20 just for bare editing functionality). I prefer projects with as few dependencies as possible. If you run `filegen.d`, it will put all the text-based dependencies into a single file called `dependencies.txt`. The other, an image needed for the menu bar, cannot be stored in that file, so that means there are two dependencies.

You can create the `dependencies.txt` file:

```
make deps
```

# editor.d

The example editor uses [cgi.d](https://github.com/adamdruppe/arsd/blob/master/cgi.d) to start a web server that can be used to edit files in the current working directory inside your browser.

```
make
./editor
```

That starts the editor inside the repo; normally you'll want to copy the `editor` binary to somewhere on your PATH, like `~/bin`.

The app has two functions. You can edit the file foo.md by opening the URL

```
localhost:8085/edit?file=foo.md
```

If `foo.md` doesn't exist, it will be created. You can preview the output using unstyled html, assuming a recent version of Pandoc is installed, by opening the URL

```
localhost:8085/view?file=foo.md
```

Note that this previews the most recent *saved* version of the file in a new tab. If you have unsaved edits, they will not appear.

# Additional Functionality

The app itself is pretty limited (creating, editing, and limited viewing of files) and that's intentional. It's nothing more than an easy-to-follow example, not an app that others will want to use.

# Creating This File

I created the file you're reading right now using the editor. I did the following (on Linux, with Pandoc installed).

1\. Clone the repo and compile the app:

```
make deps
make
```

2\. Run the app:

```
./editor
```

3\. Open the file for editing in the browser by going to the URL

```
localhost:8085/edit?file=readme.md
```

Since there was no file of that name in the working directory, it created a new file called readme.md.

4\. Type away and commit it to the repo when finished.