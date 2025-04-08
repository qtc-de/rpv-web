# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## v1.4.1 - Apr 08, 2025

### Added

* Add human readable name for transfer syntax

### Changed

* Fix text overflow in interface details pane
* Fix jumping to decompiled methods not working
* Fix renaming of methods and sec callbacks
* Fix command line interface not working
* Creating a tab that already exists jumps to it
* Update frontend dependencies


## v1.4.0 - Mar 29, 2025

### Changed

* Switch from `vweb` to `veb` module
* Switch from `x.json2` to `json` module
* Get rid of global variables
* Fix rpv-web binding to other interfaces


## v1.3.0 - July 29, 2024

### Added

* Add RPC interface filter
* Add support for negative filters
* Add RPC interface version in interface pane
* Add module base address to interface details

### Changed

* Make process filter persistent when tab is changed
* MIDL view now jumps to selected method


## v1.2.1 - July 19, 2024

### Changed

* Fix `-pdb-path` not working with `-snapshot`
* Updated GitHub actions in workflow files


## v1.2.0 - July 17, 2024

### Added

* Add offset property for *RPC Methods*
* Add offset property for *Security Callbacks*
* Add separate icon for *x86* version of rpv-web

### Changed

* Fix type errors caused by newer v versions
* Fix incorrect attr syntax in newer v versions
* Use separate builder container in Dockerfile
* Rename `base` property of *RPC Methods* to `addr`
* Rename `base` property of *Security Callbacks* to `addr`


## v1.1.0 - Sep 22, 2023

### Added

* Add resource files to compiled executable (icon and file info)

### Changed

* Compile executables with `-prod`
* Remove version pinning of *v* from CI


## v1.0.0 - Sep 08, 2023

Initial Release :)
