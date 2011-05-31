#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

module Puppet::Util
    describe Extlookup do
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
