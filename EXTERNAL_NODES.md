Extlookup External Node Classifier
==================================

A main part of extlookup functionality isn't
about the function or its use it's about the data
model that it proposes.  Thus far there has been very
little use made of the data outside of Puppet.

As part of the rewrite I want to make the data easier
to query by external tools.  This is a dump of what an
extlookup ENC might look like.

  * you want to specify the classes to apply in the same way you do data
  * you want to have different classes for different roles/datacenters/environments
  * you want param classes that understand extlookup magically

With the config/data below a production machine will have the equivalent of:

<pre>
node "foo" {
   # $country is a fact == uk

   # a hash because not all possible keys in external data
   # would translate to valid variable names.  Not tested if
   # ENCs can set hash data though.
   $data["sysadmin_contact"] = "sysadmin@example.com"
   $data["foo.com"] = {"docroot" => "/var/www/foo.com",
                       "contact" => "webmaster@foo.com"}
   $data["ntpservers"] = ["1.uk.pool.ntp.org", "2.uk.pool.ntp.org"]

   include users::common
   include users::production

   class{"ntp::client":
      ntpservers => ["1.uk.pool.ntp.org", "2.uk.pool.ntp.org"]
   }
}
</pre>

extlookup configuration
-----------------------

<pre>
---
:parser: YAML
:classeslist: classes
:precedence:
- country_%{country}
- environment_%{environment}
- common
:yaml:
  :datadir: /etc/puppet/extdata
</pre>

country_uk.yaml
---------------

<pre>
---
ntpservers:
- 1.uk.pool.ntp.org
- 2.uk.pool.ntp.org
</pre>

environment_production.yaml
---------------------------

<pre>
---
classes:
- users::production
- ntp::client:
    ntpservers: :ntpservers
foo_vhost:
  contact: webmaster@foo.com
  docroot: /var/www/foo.com
</pre>

common.yaml
-----------

<pre>
---
classes:
- users::common
sysadmin_contact: sysadmin@example.com
</pre>


Extra possibilities
===================

Per node ENC side data
----------------------
I favor a model where nodes have facts that declare their roles,
this is so mcollective can reuse this data and so you can pass it
into new nodes at node creation in the cloud for example using
user data.

This isn't always desirable so we might have a per node data file
that can be queried for a set of fact like data - this could be
role etc that might then be used in the precedence.

Credit Dan Bode for the idea
