# Star creator for Hades Star

A simple app which allows you to create stars and check distances between objects.

Information is stored in Firebase.

## Developing

### Install the Dart SDK

First you will need to download and install the Dart SDK which can be found at
https://www.dartlang.org/install.

### Download dependencies from pub (similar to npm)

`pub` is a utility that ships with the sdk, assuming that is on your PATH you
can run `pub upgrade` to download all your dependencies. These are specified
in the `pubspec.yaml` file which you can look at if your are curious, or need
to add new dependencies.

### Run the build server

The server is called `build_runner` and comes from one of your
`dev_dependencies` (see pubspec.yaml).

To run it, you use the `pub run build_runner serve` command. This will start
a dev server that watches your filesystem and compiles code to JS, and serves
it to the browser.

### Deploying

To deploy, you need to globally activate the `peanut` package, using the
`pub global activate peanut` command.

Then, you just run `peanut`, which will build a deployed version of the app
and commit it to the local `gh-pages` branch.

Next, you just need to push your local `gh-pages` branch to the remote
`gh-pages` branch and it will be live in a few minutes! (you can do this
with `git push origin gh-pages`).