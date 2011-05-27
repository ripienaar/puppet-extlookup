module Puppet::Parser::Functions
    newfunction(:lookup, :type => :rvalue) do |args|
        key = args[0] || nil
        default = args[1] || nil
        override = args[2] || nil

        configfile = File.join([File.dirname(Puppet.settings[:config]), "extlookup.yaml"])

        raise(Puppet::ParseError, "Extlookup config file #{configfile} not readable") unless File.exist?(configfile)

        config = YAML.load_file(configfile)
        parser = config[:parser] || "CSV"

        require "puppet/util/extlookup/#{parser.downcase}_parser"

        parser = Kernel.const_get("Puppet").const_get("Util").const_get("Extlookup").const_get("#{parser}_Parser")
        parser.lookup(key, default, override, config, self.to_hash)
    end
end
