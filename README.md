# kernel-autobuild-overlay

A Gentoo Portage Overlay which contains an enhanced kernel-2.eclass and some
tools.

The aim of this overlay is to support automatically building, upgrading,
installing, and removing kernel packages using only emerge where possible.

This overlay includes 3 new things to be aware of:
* USE Flags
* make.conf options
* kernel-option-viewer tools

## USE Flags

The eclass adds 3 new USE flags:

| USE Flag    | Description                                            |
| ----------- | ------------------------------------------------------ |
| autobuild   | imports your old .config and compile the new kernel    |
| autoinstall | after compiling the kernel, also attempt to install it |
| autoremove  | attempt to remove older kernel sources                 |

## make.conf options

The eclass also allows for several new options in your make.conf:

* KERNEL_OPTION_VIEWER:
The viewer command, which shows new kernel options.  This should
run an interactive background process (pop up an xterm, start a new screen
window, or even openvt).  The first argument to this command is the full path
to a file containing a list of new kernel options (since the previous version)
which need configuring.
Example:
```
KERNEL_OPTION_VIEWER="/usr/local/kernel-autobuild-portage/sys-kernel/kernel-option-viewer/files/kernel_option_viewer.sh"
```

* KERNEL_CONFIG_METHOD
This selects the method for configuring the kernel.  Valid options are:
xconfig, gconfig, menuconfig, nconfig, config
Example:
```
KERNEL_CONFIG_METHOD="xconfig"
```

* KERNEL_POST_INSTALL
A command to run after successfully installing the compiled kernel.  This
generally is a script which updates the boot loader (lilo, grub-mkconfig,
boot-update, etc.)
On Funtoo, this is usually /sbin/boot-update
On Gentoo, this might be some variation of grub-mkconfig
An empty string indicates that nothing should be run.
```
KERNEL_POST_INSTALL="/sbin/boot-update"
```

## kernel-option-viewer tools

This tool allows you to easily detect new kernel options that were not
available in the old .config file.  This reduces the manual effort of upgrading
your kernel to just a matter of looking at those new options, configuring them,
and allowing the build/install system to handle the redundant details of the
install.

The script offers 2 forms of output:
* text - This is a tab-indented list of kernel options as they are named in the
menu-based configuration tools (such as "make menuconfig").  This makes it
easier to find the new options to configure them.  This mode offers basic
functionality to text-only environments without access to higher level tools.
This is generally intended as a last resort for when HTML output is not
available.
* html - This is a more functional and visually helpful version of the kernel
options listed in text mode.  This provides a temporary HTML file listing the
config options as they appear in menu-based configuration tools (such as "make
menuconfig").  the nicely indented list shows the same hierarchy as
configuration tools and allows you to click an option to grey it out and hide
any sub-items in a list.  This makes it act as an interactive checklist when
going through configuration of a kernel.
