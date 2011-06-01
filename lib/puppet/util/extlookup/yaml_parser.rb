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

                def lookup(key)
                    answer = nil
                    precedence = nil

                    Puppet.debug("extlookup/yaml: looking for key=#{key} with default=#{@default}")

                    raise(Puppet::ParseError, "Extlookup YAML backend is unconfigured") unless @config.include?(:yaml)

                    datadir = Extlookup.datadir(@config, :yaml, :datadir)

                    Extlookup.datasources(@config, @override, precedence) do |source|
                        source = Extlookup.parse_data_contents(source, @scope)
                        file = File.join([datadir, "#{source}.yaml"])

                        if answer.nil?
                            Puppet.debug("extlookup/yaml: Looking for data in #{file}")

                            if File.exist?(file)
                                data = YAML.load_file(file)

                                next if data.empty?
                                next unless data.include?(key)

                                if data[key].is_a?(String)
                                    answer = Extlookup.parse_data_contents(data[key], @scope)
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
