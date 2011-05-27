What?
=====

A version of extlookup with a pluggable backend.  The same
puppet manifests can be configured to query different backends
like a backward compatible CSV file, YAML files or in-module
data.

At present only a CSV file backend is implimented, the rest
will follow.

Configuration?
==============

You need a YAML file in the same directory as your puppet.conf
it looks something like this:

   ---
   :parser: CSV
   :precedence:
   - test_%{environment}
   - common
   :csv:
      :datadir: /home/rip/work/github/puppet-extlookup/extdata

Status?
=======

This is a work in progress, do not use yes.

Contact?
========

R.I.Pienaar / rip@devco.net / www.devco.net / @ripienaar
