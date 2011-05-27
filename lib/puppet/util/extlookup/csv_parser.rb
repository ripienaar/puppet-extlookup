module Puppet
    module Util
        module Extlookup
            class CSV_Parser
                require 'csv'

                class << self
                    def datasources(datadir, override, precedence, scope)
                        sources = []

                        [precedence].flatten.map do |file|
                            file = parse_data_contents(file, scope)

                            File.join([datadir, "#{file}.csv"])
                        end
                    end

                    # parse %{}'s in the CSV into local variables using lookupvar()
                    def parse_data_contents(data, scope)
                        tdata = data.clone

                        while tdata =~ /%\{(.+?)\}/
                            tdata.gsub!(/%\{#{$1}\}/, scope[$1])
                        end

                        return tdata
                    end

                    def datadir(config)
                        datadir = File.join(File.dirname(Puppet.settings[:config]), "extdata")

                        if config[:csv][:datadir]
                            datadir = config[:csv][:datadir]
                        else
                            Puppet.notice("Using #{datadir} for extlookup CSV data as no datadir is configured")
                        end

                        raise(Puppet::ParseError, "Extlookup CSV datadir not found") unless File.directory?(datadir)

                        return datadir
                    end

                    def parse_csv(data, scope)
                        Puppet.debug("extlookup/csv parsing #{data} for special characters")

                        answer = nil

                        # return just the single result if theres just one,
                        # else take all the fields in the csv and build an array
                        if data.length > 0
                            if data[0].length == 2
                                val = data[0][1].to_s

                                answer = parse_data_contents(val, scope)
                            end
                        elsif data[0].length > 1
                            length = data[0].length
                            cells = data[0][1,length]

                            # Individual cells in a CSV result are a weird data type and throws
                            # puppets yaml parsing, so just map it all to plain old strings
                            answer = cells.map do |cell|
                                cell = parse_data_contents(cell, scope)
                                cell.to_s
                            end
                        end

                        return answer.to_s
                    end

                    def lookup(key, default, override, config, scope)
                        answer = nil

                        Puppet.debug("extlookup/csv looking for key=#{key} with default=#{default}")

                        raise(Puppet::ParseError, "Extlookup CSV backend is unconfigured") unless config.include?(:csv)

                        precedence = config[:precedence] || ["common"]

                        csvdir = datadir(config)
                        Puppet.debug("extlookup/csv Looking for data in #{csvdir}")

                        datasources(csvdir, override, precedence, scope).each do |file|
                            if answer.nil?
                                Puppet.debug("extlookup/csv Looking for data in #{file}")

                                if File.exist?(file)
                                    data = CSV.read(file).find_all {|r| r[0] == key}

                                    next if data.empty?

                                    answer = parse_csv(data, scope)
                                end
                            end
                        end

                        answer || default or raise(Puppet::ParseError, "No match found for '#{key}' in any data file during extlookup")
                    end
                end
            end
        end
    end
end
