require 'spec_helper'
require 'mamiya/agent/tasks/abstract'

describe Mamiya::Agent::Tasks::Abstract do
  let(:queue) { double('task_queue') }

  let(:job) { {'foo' => 'bar'} }
  subject(:task) { described_class.new(queue, job) }

  describe "#task" do
    before do
      allow(described_class).to receive(:identifier).and_return('ident')
    end
    it "includes job specification and class' identifier" do
      expect(task.task['foo']).to eq 'bar'
      expect(task.task['task']).to eq described_class.identifier
    end
  end

  describe "#execute" do
    it "calls before, then run" do
      expect(task).to receive(:before).ordered
      expect(task).to receive(:run).ordered
      task.execute
    end
    it "calls after" do
      expect(task).to receive(:run).ordered
      expect(task).to receive(:after).ordered
      expect(task).not_to receive(:error)
      task.execute
    end

    it "handles error" do
      expect(task).to receive(:after)
      expect(task).to receive(:errored)

      err = RuntimeError.new
      allow(task).to receive(:run).and_raise(err)

      task.execute

      expect(task.error).to eq err
    end

    context "with _chain" do
      let(:job) { {'foo' => 'bar', '_chain' => ['another']} }

      it "enqueues next _chain, keeping same task specification" do
        expect(queue).to receive(:enqueue).with(:another,
          'foo' => 'bar',
        )

        task.execute
      end
    end

    context "with multiple _chain" do
      let(:job) { {'foo' => 'bar', '_chain' => ['b', 'c']} }

      it "enqueues next _chain, keeping same task specification" do
        expect(queue).to receive(:enqueue).with(:b,
          'foo' => 'bar',
          '_chain' => ['c'],
        )

        task.execute
      end
    end

    context "with empty _chain" do
      let(:job) { {'foo' => 'bar', '_chain' => []} }

      it "doesn't enqueue nothing" do
        expect(queue).not_to receive(:enqueue)
        task.execute
      end
    end

  end

  describe ".identifier" do
    it "returns class name without module name" do
      allow(described_class).to receive(:name).and_return('Mamiya::Agent::Tasks::Foo')
      expect(described_class.identifier).to eq 'foo'
    end

    it "returns camelcased class name" do
      allow(described_class).to receive(:name).and_return('Mamiya::Agent::Tasks::FooBar')
      expect(described_class.identifier).to eq 'foo_bar'
    end
  end
end

