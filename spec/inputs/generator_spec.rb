require "logstash/devutils/rspec/spec_helper"
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

    insist { events[0]["sequence"] } == 0
    insist { events[0]["message"] } == "foo"

    insist { events[1]["sequence"] } == 1
    insist { events[1]["message"] } == "foo"
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

    saved_stdin = $stdin
    stdin_mock = StringIO.new
    $stdin = stdin_mock
    expect(stdin_mock).to receive(:readline).once.and_return("bar")

    events = input(conf) do |pipeline, queue|
      2.times.map{queue.pop}
    end

    insist { events[0]["sequence"] } == 0
    insist { events[0]["message"] } == "bar"

    insist { events[1]["sequence"] } == 1
    insist { events[1]["message"] } == "bar"

    $stdin = saved_stdin
  end
end
