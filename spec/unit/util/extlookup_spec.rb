#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

module Puppet::Util
    describe Extlookup do
        describe "#datadir" do
            it "should default to configured data dir" do
                config = mock
                config.expects("[]").with(:csv).returns({:datadir => "/tmp"})
                store = mock
                store.expects(:lookupvar).never

                Puppet::Util::Extlookup.datadir(config, :csv, :datadir,store).should == "/tmp"
            end

            it "should default to Puppet configdir + extdata for data if unconfigured" do
                config = mock
                config.expects("[]").with(:csv).returns({})
                store = mock
                store.expects(:lookupvar).never

                Puppet.expects(:settings).returns({:config => "/tmp/puppet.conf"})
                File.expects(:directory?).with("/tmp/extdata").returns(true)

                Puppet::Util::Extlookup.datadir(config, :csv, :datadir,store).should == "/tmp/extdata"
            end

            it "should fail if the datadir does not exist" do
                config = mock
                config.expects("[]").with(:csv).returns({:datadir => "/nonexisting"})
                store = mock
                store.expects(:lookupvar).never

                expect {
                    Puppet::Util::Extlookup.datadir(config, :csv, :datadir, store)
                }.to raise_error("Extlookup datadir (/nonexisting) not found")
            end

            it "should substitute variables in datadir" do
                config = mock
                config.expects("[]").with(:csv).returns({:datadir => "/some/path/with/variables/%{test}/in/path"})
                store = mock
                store.expects(:lookupvar).with("test").returns("data")
                store.expects(:respond_to?).with(:lookupvar).returns(true)
                File.expects(:directory?).with("/some/path/with/variables/data/in/path").returns(true)

                Puppet::Util::Extlookup.datadir(config, :csv, :datadir,store).should == "/some/path/with/variables/data/in/path"
            end
        end

        describe "#parse_data_contents" do
            it "should clone the data" do
                data = mock(:clone)
                Puppet::Util::Extlookup.parse_data_contents(data, {})
            end

            it "should support Puppet scope variables" do
                store = mock
                store.expects(:lookupvar).with("test").returns("data")
                store.expects(:respond_to?).with(:lookupvar).returns(true)

                Puppet::Util::Extlookup.parse_data_contents("test_%{test}_test_%{test}", store).should == "test_data_test_data"
            end

            it "should support Hash variables" do
                store = mock
                store.expects("[]").with("test").returns("data")
                store.expects(:respond_to?).with(:lookupvar).returns(false)
                store.expects(:respond_to?).with("[]").returns(true)

                Puppet::Util::Extlookup.parse_data_contents("test_%{test}_test_%{test}", store).should == "test_data_test_data"
            end

            it "should raise an error for unknown data types" do
                store = mock
                store.expects(:respond_to?).with(:lookupvar).returns(false)
                store.expects(:respond_to?).with("[]").returns(false)

                expect {
                Puppet::Util::Extlookup.parse_data_contents("test_%{test}_test_%{test}", store)
                }.to raise_error("Don't know how to extract data from a store of type Mocha::Mock")
            end
        end

        describe "#datasources" do
            it "should use a common datasource if no precedence is specified or configured" do
                sources = []

                Puppet::Util::Extlookup.datasources({}) do |source|
                    sources << source
                end

                sources.should == ["common"]
            end

            it "should allow for a custom precedence" do
                sources = []

                Puppet::Util::Extlookup.datasources({}, nil, "custom") do |source|
                    sources << source
                end

                sources.should == ["custom"]
            end

            it "should add an override precedence" do
                sources = []

                Puppet::Util::Extlookup.datasources({}, "override") do |source|
                    sources << source
                end

                sources.should == ["override", "common"]
            end

            it "should allow both custom precedence and an override" do
                sources = []

                Puppet::Util::Extlookup.datasources({}, "override", "custom") do |source|
                    sources << source
                end

                sources.should == ["override", "custom"]
            end
        end
    end
end
