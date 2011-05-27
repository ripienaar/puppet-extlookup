What?
=====

A version of extlookup with a pluggable backend.  The same
puppet manifests can be configured to query different backends
like a backward compatible CSV file, YAML files or in-module
data.

Configuration?
==============

You need a YAML file called extlookup.yaml in the same directory as
your puppet.conf it looks like the examples below

Parsers?
========

CSV
---

Compatible with old extlookup, all the feature of the old extlookup
and supports config using the old global variables and if those
don't exist the new config file

To configure just set :datadir to a directory full of files ending
in .csv

<pre>
   ---
   :parser: CSV
   :precedence:
   - environment_%{environment}
   - common
   :csv:
      :datadir: /etc/puppet/extdata
</pre>

This configures the function to look in a per environment
CSV file and then in a common one.  Files are stored in
/etc/puppet/extdata

This is equivelant to the old config:

<pre>
$extlookup_datadir = "/etc/puppet/extdata"
$extlookup_precedence = ["environment_%{environment}", "common"]
</pre>

YAML
----

A YAML parser that supports the same precedence and overrides.
For simple String data it will do variable parsing like the old
CSV extlookup but if you put a hash or arrays of hashes in your
data it wont touch those.

<pre>
---
:parser: YAML
:precedence:
- environment_%{environment}
- common
:yaml:
   :datadir: /etc/puppet/extdata
</pre>

This configuration matches the above CSV configuration, all you
need to do is create yaml files instead of CSV files.

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

You can also configure explicit behavior like proposed by
Nigel:

<pre>
---
:parser: Puppet
:precedence:
- %{calling_class}
- %{calling_module}
:puppet:
   :datasource: data
</pre>

Status?
=======

This is a work in progress, use at your own risk

Contact?
========

R.I.Pienaar / rip@devco.net / www.devco.net / @ripienaar
