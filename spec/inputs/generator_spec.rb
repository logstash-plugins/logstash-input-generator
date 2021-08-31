require "logstash/devutils/rspec/spec_helper"
require "logstash/devutils/rspec/shared_examples"
require 'logstash/plugin_mixins/ecs_compatibility_support/spec_helper'

require "logstash/inputs/generator"

describe LogStash::Inputs::Generator, :ecs_compatibility_support do

  it_behaves_like "an interruptible input plugin" do
    let(:config) { { } }
  end

  ecs_compatibility_matrix(:disabled, :v1, :v8) do |ecs_select|

    before(:each) do
      allow_any_instance_of(described_class).to receive(:ecs_compatibility).and_return(ecs_compatibility)
    end

    let(:sequence_field) do
      ecs_select.active_mode == :disabled ? 'sequence' : '[event][sequence]'
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
        2.times.map { queue.pop }
      end

      events.each { |event| expect( event.get("message") ).to eql 'foo' }

      expect( events.first.get(sequence_field) ).to be_an Integer

      events = events.sort_by { |e| e.get(sequence_field) }
      expect( events[0].get(sequence_field) ).to eql 0
      expect( events[1].get(sequence_field) ).to eql 1
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
        2.times.map { queue.pop }
      end

      events.each { |event| expect( event.get("message") ).to eql 'bar' }

      events = events.sort_by {|e| e.get(sequence_field) }
      expect( events[0].get(sequence_field) ).to eql 0
      expect( events[1].get(sequence_field) ).to eql 1
    end

    after { $stdin = STDIN }

  end

end
