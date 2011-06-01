#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../../spec_helper'

module Puppet::Util::Extlookup
    require 'puppet/util/extlookup/csv_parser'

    describe CSV_Parser do
        before do
            Puppet.stubs(:debug)
            Puppet.stubs(:notice)
        end

        describe "#backward_compat_datadir" do
            it "should default to configured data dir" do
                config = mock
                config.expects("[]").with(:csv).returns({:datadir => "/tmp"})

                csv = CSV_Parser.new(nil, nil, config, nil)
                csv.backward_compat_datadir.should == "/tmp"
            end

            it "should default to Puppet configdir + extdata for data if unconfigured" do
                config = mock
                config.expects("[]").with(:csv).returns({})

                Puppet.expects(:settings).returns({:config => "/tmp/puppet.conf"})
                File.expects(:directory?).with("/tmp/extdata").returns(true)

                csv = CSV_Parser.new(nil, nil, config, nil)
                csv.backward_compat_datadir.should == "/tmp/extdata"
            end

            it "should support backwards compat $extlookup_datadir variable" do
                scope = mock
                scope.expects(:respond_to?).with(:lookupvar).returns(true)
                scope.expects(:lookupvar).with("extlookup_datadir").returns("/tmp/extdata")
                File.expects(:directory?).with("/tmp/extdata").returns(true)

                csv = CSV_Parser.new(nil, nil, {}, scope)
                csv.backward_compat_datadir.should == "/tmp/extdata"
            end

            it "should fail if the datadir does not exist" do
                config = mock
                config.expects("[]").with(:csv).returns({:datadir => "/nonexisting"})

                csv = CSV_Parser.new(nil, nil, config, nil)
                expect {
                    csv.backward_compat_datadir
                }.to raise_error("Extlookup CSV datadir (/nonexisting) not found")
            end

            it "should substitute variables in datadir" do
                config = mock
                config.expects("[]").with(:csv).returns({:datadir => "/some/path/with/variables/%{test}/in/path"})
                scope = mock
                scope.expects(:lookupvar).with("test").returns("data")
                scope.stubs(:respond_to?).with(:lookupvar).returns(true)
                scope.expects(:lookupvar).with('extlookup_datadir').returns("")
                File.expects(:directory?).with("/some/path/with/variables/data/in/path").returns(true)

                csv = CSV_Parser.new(nil, nil, config, scope)
                csv.backward_compat_datadir.should == "/some/path/with/variables/data/in/path"
            end
        end

        describe "#parse_csv" do
            it "should parse and return just a single value" do
                Puppet::Util::Extlookup.expects(:parse_data_contents).with("value", nil).returns("parsed_value")
                csv = CSV_Parser.new(nil, nil, nil, nil)
                csv.parse_csv(["key", "value"]).should == "parsed_value"
            end

            it "should parse and return multiple values as an array" do
                Puppet::Util::Extlookup.expects(:parse_data_contents).with("value1", nil).returns("parsed_value1")
                Puppet::Util::Extlookup.expects(:parse_data_contents).with("value2", nil).returns("parsed_value2")

                csv = CSV_Parser.new(nil, nil, nil, nil)
                csv.parse_csv(["key", "value1", "value2"]).should == ["parsed_value1", "parsed_value2"]
            end
        end

        describe "#lookup" do
            it "should error when unconfigured" do
                config = mock
                config.expects(:include?).with(:csv).returns(false)

                csv = CSV_Parser.new(nil, nil, config, nil)
                expect {
                    csv.lookup("data")
                }.to raise_error("Extlookup CSV backend is unconfigured")
            end

            it "should support backwards compat $extlookup_precedence" do
                scope = mock
                scope.expects(:lookupvar).with("extlookup_precedence").returns("precedence").twice

                config = mock
                config.expects(:include?).with(:csv).returns(true)

                Puppet::Util::Extlookup.expects(:datasources).with(config, nil, "precedence").yields(["source"])
                File.expects(:exist?).with("/tmp/source.csv").returns(true)
                CSV.expects(:read).returns([["data", "value"]])

                csv = CSV_Parser.new(nil, nil, config, scope)
                csv.expects(:backward_compat_datadir).returns("/tmp")

                csv.lookup("data").should == "value"
            end

            it "should return default data if supplied" do
                scope = mock
                scope.expects(:lookupvar).with("extlookup_precedence").returns("precedence").twice

                config = mock
                config.expects(:include?).with(:csv).returns(true)

                Puppet::Util::Extlookup.expects(:datasources).with(config, nil, "precedence").yields(["source"])
                File.expects(:exist?).with("/tmp/source.csv").returns(true)
                CSV.expects(:read).returns([])

                csv = CSV_Parser.new("default", nil, config, scope)
                csv.expects(:backward_compat_datadir).returns("/tmp")

                csv.lookup("data").should == "default"
            end

            it "should error if no data and no default is found" do
                scope = mock
                scope.expects(:lookupvar).with("extlookup_precedence").returns("precedence").twice

                config = mock
                config.expects(:include?).with(:csv).returns(true)

                Puppet::Util::Extlookup.expects(:datasources).with(config, nil, "precedence").yields(["source"])
                File.expects(:exist?).with("/tmp/source.csv").returns(true)
                CSV.expects(:read).returns([])

                csv = CSV_Parser.new(nil, nil, config, scope)
                csv.expects(:backward_compat_datadir).returns("/tmp")

                expect {
                    csv.lookup("data")
                }.to raise_error("No match found for 'data' in any data file during extlookup")
            end
        end
    end
end
