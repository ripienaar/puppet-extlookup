#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

module Puppet::Util::Extlookup
    require 'puppet/util/extlookup/yaml_parser'

    describe YAML_Parser do
        before do
            Puppet.stubs(:debug)
            Puppet.stubs(:notice)
        end

        describe "#lookup" do
            it "should error when unconfigured" do
                config = mock
                config.expects(:include?).with(:yaml).returns(false)

                csv = YAML_Parser.new(nil, nil, config, nil)
                expect {
                    csv.lookup("data")
                }.to raise_error("Extlookup YAML backend is unconfigured")
            end

            it "should return default data if supplied" do
                config = mock
                config.expects(:include?).with(:yaml).returns(true)
                config.expects("[]").with(:yaml).returns({:datadir => "/tmp"})

                Puppet::Util::Extlookup.expects(:datasources).with(config, nil, nil).yields(["source"])
                File.expects(:exist?).with("/tmp/source.yaml").returns(true)
                YAML.expects(:load_file).with("/tmp/source.yaml").returns({})

                yaml = YAML_Parser.new("default", nil, config, {})

                yaml.lookup("data").should == "default"
            end

            it "should return data from the yaml if found and no default is set" do
                config = mock
                config.expects(:include?).with(:yaml).returns(true)
                config.expects("[]").with(:yaml).returns({:datadir => "/tmp"})

                Puppet::Util::Extlookup.expects(:datasources).with(config, nil, nil).yields(["source"])
                File.expects(:exist?).with("/tmp/source.yaml").returns(true)
                YAML.expects(:load_file).with("/tmp/source.yaml").returns({"data" => "value"})

                yaml = YAML_Parser.new("default", nil, config, {})

                yaml.lookup("data").should == "value"
            end

            it "should error if no data and no default is found" do
                config = mock
                config.expects(:include?).with(:yaml).returns(true)
                config.expects("[]").with(:yaml).returns({:datadir => "/tmp"})

                Puppet::Util::Extlookup.expects(:datasources).with(config, nil, nil).yields(["source"])
                File.expects(:exist?).with("/tmp/source.yaml").returns(true)
                YAML.expects(:load_file).with("/tmp/source.yaml").returns({})

                yaml = YAML_Parser.new(nil, nil, config, {})

                expect {
                    yaml.lookup("data")
                }.to raise_error("No match found for 'data' in any data file during extlookup")
            end
        end
    end
end
