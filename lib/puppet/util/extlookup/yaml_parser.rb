module Puppet
    module Util
        module Extlookup
            class YAML_Parser
                def initialize(default, override, config, scope)
                    @default = default
                    @override = override
                    @config = config
                    @scope = scope
                end

                def datasources(precedence)
                    sources = []

                    [precedence].flatten.map do |file|
                        file = parse_data_contents(file)

                        File.join([datadir, "#{file}.yaml"])
                    end
                end

                # parse %{}'s in the data into local variables using lookupvar()
                def parse_data_contents(data)
                    tdata = data.clone

                    while tdata =~ /%\{(.+?)\}/
                        tdata.gsub!(/%\{#{$1}\}/, @scope.lookupvar($1))
                    end

                    return tdata
                end

                def datadir
                    datadir = File.join(File.dirname(Puppet.settings[:config]), "extdata")

                    if @config[:yaml][:datadir]
                        datadir = @config[:yaml][:datadir]
                    else
                        Puppet.notice("extlookup/yaml: Using #{datadir} for extlookup data as no datadir is configured")
                    end

                    raise(Puppet::ParseError, "Extlookup datadir (#{datadir}) not found") unless File.directory?(datadir)

                    Puppet.debug("extlookup/yaml: Looking for data in #{datadir}")

                    return datadir
                end

                def lookup(key)
                    answer = nil

                    Puppet.debug("extlookup/yaml: looking for key=#{key} with default=#{@default}")

                    raise(Puppet::ParseError, "Extlookup YAML backend is unconfigured") unless @config.include?(:yaml)

                    # use backward compat global variables if they exist
                    # use the config file if they dont
                    if @scope.lookupvar("extlookup_precedence") != ""
                        precedence = @scope.lookupvar("extlookup_precedence")
                    else
                        precedence = @config[:precedence] || ["common"]
                    end

                    datasources(precedence).each do |file|
                        if answer.nil?
                            Puppet.debug("extlookup/yaml: Looking for data in #{file}")

                            if File.exist?(file)
                                data = YAML.load_file(file)

                                next if data.empty?
                                next unless data.include?(key)

                                if data[key].is_a?(String)
                                    answer = parse_data_contents(data[key])
                                else
                                    answer = data[key]
                                end
                            end
                        end
                    end

                    answer || @default or raise(Puppet::ParseError, "No match found for '#{key}' in any data file during extlookup")
                end
            end
        end
    end
end
