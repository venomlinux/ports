# ports
Contain all ports for [Venom Linux](https://venomlinux.org/) used by [scratchpkg](https://github.com/venomlinux/scratchpkg)

All ports are separated into several repositories. This repositories will get sync by `scratchpkg` using a tool called `httpup`.
These are repository exist (for now):

* `core`:  Ports needed for core system.
* `extra`:  All other ports.
* `xorg`:  Ports for Xorg.
* `multilib`: Multilib ports.
* `community`: Community ports

### rep-gen

`rep-gen` is a script to generate 'REPO' file in the repository. `rep-gen` need to run after any of ports changed.

#### how to use:

    ./rep-gen <repo name>
    
or, for all exist repositories

    ./rep-gen
    
Example:

    ./rep-gen core xorg
