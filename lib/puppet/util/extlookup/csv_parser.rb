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

                def datasources(precedence)
                    sources = []

                    [precedence].flatten.map do |file|
                        file = parse_data_contents(file)

                        File.join([datadir, "#{file}.csv"])
                    end
                end

                # parse %{}'s in the CSV into local variables using lookupvar()
                def parse_data_contents(data)
                    tdata = data.clone

                    while tdata =~ /%\{(.+?)\}/
                        tdata.gsub!(/%\{#{$1}\}/, @scope.lookupvar($1))
                    end

                    return tdata
                end

                def datadir
                    datadir = File.join(File.dirname(Puppet.settings[:config]), "extdata")

                    scope_dir = @scope.lookupvar("extlookup_datadir")

                    # use the backward compat $extlookup_datadir if its
                    # set else use the config file
                    if scope_dir != ""
                        Puppet.notice("extlookup/csv: Using the global variable $extlookup_datadir is deprecated, please use a config file instead")

                        datadir = scope_dir
                    elsif @config[:csv][:datadir]
                        datadir = @config[:csv][:datadir]
                    else
                        Puppet.notice("extlookup/csv: Using #{datadir} for extlookup CSV data as no datadir is configured")
                    end

                    raise(Puppet::ParseError, "Extlookup CSV datadir (#{datadir}) not found") unless File.directory?(datadir)

                    Puppet.debug("extlookup/csv: Looking for data in #{datadir}")

                    return datadir
                end

                def parse_csv(data)
                    Puppet.debug("extlookup/csv: parsing #{data} for special characters")

                    answer = nil

                    # return just the single result if theres just one,
                    # else take all the fields in the csv and build an array
                    if data.length > 0
                        if data[0].length == 2
                            val = data[0][1].to_s

                            answer = parse_data_contents(val)
                        end
                    elsif data[0].length > 1
                        length = data[0].length
                        cells = data[0][1,length]

                        # Individual cells in a CSV result are a weird data type and throws
                        # puppets yaml parsing, so just map it all to plain old strings
                        answer = cells.map do |cell|
                            cell = parse_data_contents(cell)
                            cell.to_s
                        end
                    end

                    return answer.to_s
                end

                def lookup(key)
                    answer = nil

                    Puppet.debug("extlookup/csv: looking for key=#{key} with default=#{@default}")

                    raise(Puppet::ParseError, "Extlookup CSV backend is unconfigured") unless @config.include?(:csv)

                    # use backward compat global variables if they exist
                    # use the config file if they dont
                    if @scope.lookupvar("extlookup_precedence") != ""
                        precedence = @scope.lookupvar("extlookup_precedence")
                    else
                        precedence = [@config[:precedence]].flatten || ["common"]
                    end

                    precedence.insert(0, @override) if @override

                    datasources(precedence).each do |file|
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
