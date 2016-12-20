module Puppet::Parser::Functions
    newfunction(:extlookup, :type => :rvalue, :docs => "A version of extlookup with a pluggable backend. The same puppet manifests can be configured to query different backends like a backward compatible CSV file, YAML files or in-module data.") do |*args|
        # Functions called from Puppet manifests look like this:
        #
        #   extlookup("foo", "bar")
        # 
        # Internally in Puppet are invoked like:
        #
        #   func(["foo", "bar"])
        #
        # Whereas calling from templates should work like this:
        #   
        #   scope.function_extlookup("foo", "bar")
        #
        # Therefore, declare this function with args '*args' to accept any number
        # of arguments and deal with puppet's special calling mechanism now:
        if args[0].is_a?(Array)
            args = args[0]
        end

        key = args[0] || nil
        default = args[1] || nil
        override = args[2] || nil

        configfile = File.join([File.dirname(Puppet.settings[:config]), "extlookup.yaml"])

        raise(Puppet::ParseError, "Extlookup config file #{configfile} not readable") unless File.exist?(configfile)

        config = YAML.load_file(configfile)
        parser = config[:parser] || "CSV"

        relpath = File.join(File.dirname(__FILE__), "..", "..", "..")
        require "#{relpath}/puppet/util/extlookup"
        require "#{relpath}/puppet/util/extlookup/#{parser.downcase}_parser"

        #parser = Kernel.const_get("Puppet").const_get("Util").const_get("Extlookup").const_get("#{parser}_Parser")

        parsername = ::Puppet::Util::Extlookup.constants.grep(/^#{parser}_Parser$/i).first
        parser = ::Puppet::Util::Extlookup.const_get(parsername)
        parser = parser.new(default, override, config, self)
        parser.lookup(key)
    end
end
