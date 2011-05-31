#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

module Puppet::Util::Extlookup
    require 'puppet/util/extlookup/puppet_parser'

    describe Puppet_Parser do
        before do
            Puppet.stubs(:debug)
            Puppet.stubs(:notice)
        end


        describe "#precedence" do
            it "should use the configured data source" do
                config = mock
                config.expects("[]").with(:puppet).returns({:datasource => "custom"})
                config.expects("[]").with(:precedence)

                resource = mock
                resource.expects(:name).returns("foo::bar")

                scope = mock
                scope.expects(:resource).returns(resource)

                puppet = Puppet_Parser.new(nil, nil, config, scope)
                puppet.precedence.should == ["custom::foo::bar", "custom::foo", "foo::bar::custom", "foo::custom"]
            end

            it "should default to 'data' data source" do
                config = mock
                config.expects("[]").with(:puppet).returns({})
                config.expects("[]").with(:precedence)

                resource = mock
                resource.expects(:name).returns("foo::bar")

                scope = mock
                scope.expects(:resource).returns(resource)

                puppet = Puppet_Parser.new(nil, nil, config, scope)
                puppet.precedence.should == ["data::foo::bar", "data::foo", "foo::bar::data", "foo::data"]
            end

            it "should allow for custom precedence" do
                config = mock
                config.expects("[]").with(:puppet).returns({})
                config.expects("[]").with(:precedence).returns("%{country}")

                resource = mock
                resource.expects(:name).returns("foo::bar")

                scope = mock
                scope.expects(:resource).returns(resource)
                scope.expects(:lookupvar).with("country").returns("uk")

                puppet = Puppet_Parser.new(nil, nil, config, scope)
                puppet.precedence.should == ["data::uk", "foo::bar::data", "foo::data"]
            end

            it "should insert the override precedence" do
                config = mock
                config.expects("[]").with(:puppet).returns({})
                config.expects("[]").with(:precedence).returns("%{country}")

                resource = mock
                resource.expects(:name).returns("foo::bar")

                scope = mock
                scope.expects(:resource).returns(resource)
                scope.expects(:lookupvar).with("country").returns("uk")

                puppet = Puppet_Parser.new(nil, "override", config, scope)
                puppet.precedence.should == ["data::override", "data::uk", "foo::bar::data", "foo::data"]
            end
        end

        describe "#parse_data_contents" do
            it "should parse variables from the scope" do
                scope = mock
                scope.expects(:lookupvar).with("test_data").returns("test")

                puppet = Puppet_Parser.new(nil, nil, nil, scope)
                puppet.parse_data_contents("test_%{test_data}_test", nil, nil).should == "test_test_test"
            end

            it "should parse calling_class" do
                puppet = Puppet_Parser.new(nil, nil, nil, nil)
                puppet.parse_data_contents("test_%{calling_class}_test", "rspec", nil).should == "test_rspec_test"
            end

            it "should parse calling_module" do
                puppet = Puppet_Parser.new(nil, nil, nil, nil)
                puppet.parse_data_contents("test_%{calling_module}_test", nil, "rspec").should == "test_rspec_test"
                puppet.parse_data_contents("test_%{calling_module}_test_%{calling_class}", "class", "module").should == "test_module_test_class"
            end
        end

        describe "#lookup" do
            it "should return default data if supplied" do
                catalog = mock
                catalog.expects(:classes).returns([])

                scope = mock
                scope.expects(:catalog).returns(catalog)
                scope.expects(:function_include).with("precedence")
                scope.expects(:lookupvar).with("precedence::foo")

                Puppet::Parser::Functions.expects(:function).with(:include)

                puppet = Puppet_Parser.new("default", nil, nil, scope)

                puppet.expects(:precedence).returns(["precedence"])
                puppet.lookup("foo").should == "default"
            end

            it "should error if no data and no default is found" do
                catalog = mock
                catalog.expects(:classes).returns([])

                scope = mock
                scope.expects(:catalog).returns(catalog)
                scope.expects(:function_include).with("precedence")
                scope.expects(:lookupvar).with("precedence::foo")

                Puppet::Parser::Functions.expects(:function).with(:include)

                puppet = Puppet_Parser.new(nil, nil, nil, scope)

                puppet.expects(:precedence).returns(["precedence"])

                expect {
                    puppet.lookup("foo")
                }.to raise_error("No match found for 'foo' in any data file during extlookup")
            end

            it "should return found data" do
                catalog = mock
                catalog.expects(:classes).returns([])

                scope = mock
                scope.expects(:catalog).returns(catalog)
                scope.expects(:function_include).with("precedence")
                scope.expects(:lookupvar).with("precedence::foo").returns("value")

                Puppet::Parser::Functions.expects(:function).with(:include)

                puppet = Puppet_Parser.new("default", nil, nil, scope)

                puppet.expects(:precedence).returns(["precedence"])
                puppet.lookup("foo").should == "value"
            end
        end
    end
end
