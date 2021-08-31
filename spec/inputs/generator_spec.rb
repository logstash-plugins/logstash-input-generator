require "logstash/devutils/rspec/spec_helper"
require "logstash/devutils/rspec/shared_examples"
require 'logstash/plugin_mixins/ecs_compatibility_support/spec_helper'

require "logstash/inputs/generator"

describe LogStash::Inputs::Generator do

  it_behaves_like "an interruptible input plugin" do
    let(:config) { { } }
  end

  it "should generate configured message" do
    conf = <<-CONFIG
      input {
        generator {
          count => 2
          message => "foo"
        }
      }
    CONFIG

    events = input(conf) do |pipeline, queue|
      2.times.map{queue.pop}
    end

    events = events.sort_by {|e| e.get("sequence") }

    expect( events[0].get("sequence") ).to eql 0
    expect( events[0].get("message") ).to eql 'foo'

    expect( events[1].get("sequence") ).to eql 1
    expect( events[1].get("message") ).to eql 'foo'
  end

  it "should generate message from stdin" do
    conf = <<-CONFIG
      input {
        generator {
          count => 2
          message => "stdin"
        }
      }
    CONFIG

    $stdin = stdin_mock = StringIO.new
    expect(stdin_mock).to receive(:readline).once.and_return("bar")

    events = input(conf) do |pipeline, queue|
      2.times.map{queue.pop}
    end

    events = events.sort_by {|e| e.get("sequence") }

    expect( events[0].get("sequence") ).to eql 0
    expect( events[0].get("message") ).to eql 'bar'

    expect( events[1].get("sequence") ).to eql 1
    expect( events[1].get("message") ).to eql 'bar'
  end

  after { $stdin = STDIN }

end
