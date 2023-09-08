### rpv-web

----

*rpv-web* is a browser based frontend for the [rpv](https://github.com/qtc-de/rpv)
library. The frontend is written in [Vue](https://vuejs.org/) whereas the backend
utilizes *v's* builtin [web framework](https://github.com/vlang/v/tree/master/vlib/vweb).
The overall design was strongly influenced by the *Qt* based application
[RpcView](https://www.rpcview.org/).


### Installation

----

Since *v* is in it's open beta, it is expected that things change and that *rpv-web*
does not always compile with the latest *v* version. It is therefore recommended to
download the latest build from the [release](https://github.com/qtc-de/rpv-web/releases/latest)
section of the project.

If you want to build from source, you can do so. Assuming that *v* is installed, you
can run the following commands to build *rpv-web*:

```console
[user@host ~]$ v install qtc_de.rpv
[user@host ~]$ https://github.com/qtc-de/rpv-web
[user@host ~]$ cd rpv-web
[user@host rpv-web]$ make
```

If successful, you should find `rpv-web-x64.exe` within your current working directory.
Notice that building the x86 version of *rpv-web* requires additional installation steps
as described [here](https://github.com/qtc-de/rpv#installation). This will hopefully no
longer be necessary in [future versions of v](https://github.com/vlang/v/discussions/18670).

The frontend can be build using container frameworks like *docker* or *podman*. However,
also here it is recommended to use the [release builds](https://github.com/qtc-de/rpv-web/releases/latest)
instead.

```console
[user@host ~/rpv-web]$ cd frontend
[user@host frontend]$ docker build -t rpv-web .
[user@host frontend]$ docker run --rm rpv-web
[user@host frontend]$ docker cp <CONTAINER>:/app/dist .
```


### Usage

----

After installation, make sure that the frontend (`dist` folder) and the *rpv-web*
executable (e.g. `rpv-web-x64.exe`) are placed next to each other. Starting the
*rpv-web* executable should open port `8000` on `localhost` where you can access
the *rpv-web* application. Binding the application to other listeners than *localhost*
is not recommended (see [disclaimer](#disclaimer)).

More detailed usage examples can be found within the [projects wiki pages](https://github.com/qtc-de/rpv-web/wiki).


### Offline Version

----

*rpv-web* provides also an *offline version*, which is a separate frontend that can be
used without the *rpv-web* executable. The *offline version* can also be downloaded from
the [release builds](https://github.com/qtc-de/rpv-web/releases/latest) or build manually
by adding the `-- --mode offline` to the `npm run build` command. However, the recommended
way is to use the [GitHub Pages deployment](https://qtc-de.github.io/rpv-web/) from this
repository.

Within the offline version, no *live RPC* data is displayed. However, you can upload
previously created snapshots and work with them (see [snapshot documentation](https://github.com/qtc-de/rpv-web/wiki/snapshots)).
The offline version of *rpv-web* works truly offline. It is a single page application
that does not send any of your data to the application server.


### Disclaimer

----

*rpv-web* should not be accessible by untrusted clients. *rpv* and *rpv-web* contain many
*unsafe* code blocks, that bypass the memory safety features of *v*. This is required, to
get the *C* interop working, but may introduce well known memory corruption bugs. Therefore,
the application should only be used for local research projects and should not be exposed
to untrusted clients.

Regarding the frontend, it was build by a person with zero frontend development experience
(yeah, that's [me](https://twitter.com/qtc_de) :D). The frontend was tested to look reasonable
in *Firefox* and *Chrome* with a `1920x1080` screen resolution. Other browsers or screen
resolutions may not be supported. And please, whatever you do, do not visit the application
with a mobile device :D
