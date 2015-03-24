SemanticPuppet
==============

Library of useful tools for working with Semantic Versions and module
dependencies.

Description
-----------

Library of tools used by Puppet to parse, validate, and compare Semantic
Versions and Version Ranges and to query and resolve module dependencies.

For sparse, but accurate documentation, please see the docs directory.

Note that this is a 0 release version, and things can change. Expect that the
version and version range code to stay relatively stable, but the module
dependency code is expected to change.

This library is used by a number of Puppet Labs projects, including
[Puppet](https://github.com/puppetlabs/puppet) and
[r10k](https://github.com/puppetlabs/r10k).

Requirements
------------

Semantic_puppet will work on several ruby versions, including 1.9.3, 2.0.0, and
2.1.0. Ruby 1.8.7 is immediately deprecated as it is in
[r10k](https://github.com/puppetlabs/r10k).

No gem/library requirements.

Installation
------------

### Rubygems

For general use, you should install semantic_puppet from Ruby gems:

    gem install semantic_puppet

### Github

If you have more specific needs or plan on modifying semantic_puppet you can
install it out of a git repository:

    git clone git://github.com/puppetlabs/semantic_puppet

Usage
-----

SemanticPuppet is intended to be used as a library. 

### Verison Range Operator Support

SemanticPuppet will support the same version range operators as those used when
publishing modules to [Puppet Forge](https://forge.puppetlabs.com) which is
documented at 
[Publishing Modules on the Puppet Forge](https://docs.puppetlabs.com/puppet/latest/reference/modules_publishing.html#dependencies-in-metadatajson).

Contributors
------------

Pieter van de Bruggen wrote the library originally, with additions by Alex
Dreyer, Jesse Scott and Anderson Mills.
