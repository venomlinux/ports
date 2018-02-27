# ports
Contain all ports used by [scratchpkg](https://github.com/emmett1/scratchpkg)

All ports are separate into few repository. This repository will get sync by `scratchpkg` using a tool called `httpup`.
These are repository exist (for now):

* `core`:  Ports in this repository is follows BLFS SVN books.
* `extra`:  All ports outside of BLFS SVN book is in here.
* `git`:  Ports for package from git.
* `xorg`:  All ports for Xorg.
* `wip`:  Contain ports for testing package.
* `kf5`:  All ports for kde plasma 5 desktop.
* `lxde`:  All ports for lxde desktop.
* `xfce4`:  All ports for xfce4 desktop.

### rep-gen

`rep-gen` is a script to generate 'REPO' file in the repository. `rep-gen` need to run after any of ports changed.

#### how to use:

    ./rep-gen <repo name>
    
Example:

    ./rep-gen core xorg
