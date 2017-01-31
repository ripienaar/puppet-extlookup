module Puppet
    module Util
        module Extlookup
            class CSV_Parser
                require 'csv'

                def initialize(default, override, config, scope)
                    @default = default
                    @override = override
                    @config = config
                    @scope = scope
                end

                def backward_compat_datadir
                    config = @config[:csv] || {}

                    unless (datadirpath = config[:datadir])
                        datadirpath = File.join(File.dirname(Puppet.settings[:config]), "extdata")
                        Puppet.notice("extlookup/csv: Using #{datadirpath} for extlookup CSV data as no datadir is configured")
                    end
                    datadir = Extlookup.parse_data_contents(datadirpath, @scope)

                    if @scope.respond_to?(:lookupvar)
                        scope_dir = @scope.lookupvar("extlookup_datadir")

                        # use the backward compat $extlookup_datadir if its
                        # set else use the config file
                        if scope_dir != nil
                            Puppet.notice("extlookup/csv: Using the global variable $extlookup_datadir is deprecated, please use a config file instead")

                            datadir = scope_dir
                        end
                    end

                    raise(Puppet::ParseError, "Extlookup CSV datadir (#{datadir}) not found") unless File.directory?(datadir)

                    Puppet.debug("extlookup/csv: Looking for data in #{datadir}")

                    return datadir
                end

                def parse_csv(data)
                    answer = nil

                    data = [data].flatten

                    # return just the single result if theres just one,
                    # else take all the fields in the csv and build an array
                    if data.length > 0
                        if data.length == 2
                            val = data[1].to_s

                            answer = Extlookup.parse_data_contents(val, @scope)
                        elsif data.length > 2
                            length = data.length
                            cells = data[1,length]

                            # Individual cells in a CSV result are a weird data type and throws
                            # puppets yaml parsing, so just map it all to plain old strings
                            answer = cells.map do |cell|
                                cell = Extlookup.parse_data_contents(cell, @scope)
                                cell.to_s
                            end
                        end
                    end

                    return answer
                end

                def lookup(key)
                    answer = nil
                    precedence = nil

                    Puppet.debug("extlookup/csv: looking for key=#{key} with default=#{@default}")

                    raise(Puppet::ParseError, "Extlookup CSV backend is unconfigured") unless @config.include?(:csv)

                    # use backward compat global variables if they exist
                    # use the config file if they dont
                    begin
                        if @scope.lookupvar("extlookup_precedence") != nil
                            precedence = @scope.lookupvar("extlookup_precedence")
                        end
                    rescue
                    end

                    datadir = backward_compat_datadir

                    Extlookup.datasources(@config, @override, precedence) do |source|
                        source = Extlookup.parse_data_contents(source, @scope)
                        file = File.join([datadir, "#{source}.csv"])

                        if answer.nil?
                            Puppet.debug("extlookup/csv: Looking for data in #{file}")

                            if File.exist?(file)
                                data = CSV.read(file).find_all {|r| r[0] == key}

                                next if data.empty?

                                answer = parse_csv(data)
                            end
                        end
                    end

                    answer || @default or raise(Puppet::ParseError, "No match found for '#{key}' in any data file during extlookup")
                end
            end
        end
    end
end
