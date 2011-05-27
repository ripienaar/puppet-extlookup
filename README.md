What?
=====

A version of extlookup with a pluggable backend.  The same
puppet manifests can be configured to query different backends
like a backward compatible CSV file, YAML files or in-module
data.

Parsers?
========

CSV
---

Compatible with old extlookup, all the feature of the old extlookup
and supports config using the old global variables and if those
don't exist the new config file

To configure just set :datadir to a directory full of files ending
in .csv

YAML
----

A YAML parser that supports the same precedence and overrides.
For simple String data it will do variable parsing like the old
CSV extlookup but if you put a hash or arrays of hashes in your
data it wont touch those.

To configure just set :datadir to a directory full of files ending
in .yaml

Puppet
------

A parser that reads values from Puppet manifests inspired by
Nigel Kerstens get() function.  Without configured precedence
the behavior of this backend will be identical to the get()
function

In addition to the simple features of the get() function it
also includes full precedence in line with the extlookup
features.

For details of the precedence behavior for this backend see
the comments top of the backend.

Configuration?
==============

You need a YAML file in the same directory as your puppet.conf
it looks something like this:

<pre>
   ---
   :parser: CSV
   :precedence:
   - test_%{environment}
   - common
   :csv:
      :datadir: /home/rip/work/github/puppet-extlookup/extdata
</pre>

Status?
=======

This is a work in progress, use at your own risk

Contact?
========

R.I.Pienaar / rip@devco.net / www.devco.net / @ripienaar
