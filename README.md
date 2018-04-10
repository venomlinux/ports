# ports
Contains all ports used by [scratchpkg](https://github.com/emmett1/scratchpkg)

All the ports are grouped into distinct repositories. These repositories will be synced by `scratchpkg` using a tool called `httpup`.
These are the existing repositories (for the moment):

* `core`    : Ports in this repository are following the (B)LFS SVN books.
* `extra`   : All ports not mentioned in the (B)LFS SVN book, are located here.
* `git`     : Ports for packages coming from git sources.
* `xorg`    : All ports for Xorg.
* `wip`     : Contain ports for testing packages.
* `kf5`     : All ports for kde plasma 5 desktop.
* `lxde`    : All ports for lxde desktop.
* `xfce4`   : All ports for xfce4 desktop.

### rep-gen

`rep-gen` is a script to generate the 'REPO' file in the repository. `rep-gen` needs to be run after any change of ports.

#### how to use:

    ./rep-gen <repo name>
    
Example:

    ./rep-gen core xorg
