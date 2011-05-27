module Puppet
    module Util
        module Extlookup
            # Impliments the logic created by Nigel Kersten @
            # https://github.com/nigelkersten/puppet-get but
            # extends it to also support our precedence concept.
            #
            # Lookups are done by default in:
            #
            #   * data::$calling_class::myvar
            #   * data::$calling_module::myvar
            #   * $calling_class::data::myvar
            #   * $calling_module::data::myvar
            #
            # If you set :datasource in the config # then it will replace 'data' above with
            # what you configured.
            #
            # If you give a custom precdence in the main config file for example:
            #
            #    :precedence:
            #    - %{environment}
            #    - common
            #
            # The lookup order will become for machines in production:
            #
            #   * data::production::myvar
            #   * data::common::myvar
            #   * $calling_class::data::myvar
            #   * $calling_module::data::myvar
            #
            class Puppet_Parser
                def initialize(default, override, config, scope)
                    @default = default
                    @override = override
                    @config = config
                    @scope = scope
                end

                def precedence
                    begin
                        data_class = @config[:puppet][:datasource]
                    rescue
                        data_class = "data"
                    end

                    calling_class = @scope.resource.name.to_s.downcase
                    calling_module = calling_class.split("::").first

                    precedence = @config[:precedence] || [calling_class, calling_module]

                    precedence = precedence.map do |klass|
                        klass = parse_data_contents(klass, calling_class, calling_module)

                        [data_class, klass].join("::")
                    end

                    precedence << [calling_class, data_class].join("::")
                    precedence << [calling_module, data_class].join("::") unless calling_module == calling_class

                    precedence.insert(0, [data_class, @override].join("::")) if @override

                    precedence
                end

                # parse %{}'s in the precedence config to local variables using lookupvar()
                def parse_data_contents(data, calling_class, calling_module)
                    tdata = data.clone

                    while tdata =~ /%\{(.+?)\}/
                        key = $1
                        val = @scope.lookupvar(key)

                        if key == "calling_class"
                            val = calling_class
                        elsif key == "calling_module"
                            val = calling_module
                        end

                        tdata.gsub!(/%\{#{$1}\}/, val)
                    end

                    return tdata
                end

                def lookup(key)
                    answer = nil

                    Puppet.debug("extlookup/puppet: looking for key=#{key} with default=#{@default}")

                    include_class = Puppet::Parser::Functions.function(:include)
                    loaded_classes = @scope.catalog.classes

                    precedence.each do |klass|
                        if answer.nil?
                            Puppet.debug("extlookup/puppet: Looking for data in #{klass}")

                            unless loaded_classes.include?(klass)
                                begin
                                    @scope.function_include(klass)
                                    answer = @scope.lookupvar([klass, key].join("::"))
                                rescue
                                end
                            else
                                answer = @scope.lookupvar([klass, key].join("::"))
                            end
                        end
                    end

                    answer || @default or raise(Puppet::ParseError, "No match found for '#{key}' in any data file during extlookup")
                end
            end
        end
    end
end
