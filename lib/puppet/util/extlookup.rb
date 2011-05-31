module Puppet
    module Util
        module Extlookup
            class << self
                def datadir(config, key, dirkey)
                    config = config[key] || {}

                    if config[dirkey]
                        datadir = config[dirkey]
                    else
                        datadir = File.join(File.dirname(Puppet.settings[:config]), "extdata")
                        Puppet.notice("extlookup/#{key}: Using #{datadir} for extlookup data as no datadir is configured")
                    end

                    raise(Puppet::ParseError, "Extlookup datadir (#{datadir}) not found") unless File.directory?(datadir)

                    Puppet.debug("extlookup/#{key}: Looking for data in #{datadir}")

                    return datadir
                end

                def datasources(config, override=nil, precedence=nil)
                    if precedence
                        precedence = [precedence]
                    elsif config.include?(:precedence)
                        precedence = [config[:precedence]]
                    else
                        precedence = ["common"]
                    end

                    precedence.insert(0, override) if override

                    sources = []

                    precedence.flatten.map do |source|
                        yield(source)
                    end
                end

                def parse_data_contents(data, store)
                    tdata = data.clone

                    while tdata =~ /%\{(.+?)\}/
                        var = $1

                        # if running in puppet we should make best use of the
                        # scope variable by using lookupvar, else maybe someone
                        # sent us a Hash from within the ENC where we wont be getting
                        # a Puppet scope.  Would have been handy if scope had a []
                        # alias to lookupvar really
                        if store.respond_to?(:lookupvar)
                            tdata.gsub!(/%\{#{var}\}/, store.lookupvar(var))
                        elsif store.respond_to?("[]")
                            tdata.gsub!(/%\{#{var}\}/, store[var])
                        else
                            raise("Don't know how to extract data from a store of type #{store.class}")
                        end
                    end

                    return tdata
                end
            end
        end
    end
end
