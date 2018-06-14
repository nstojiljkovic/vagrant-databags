require "spec_helper"

describe VagrantPlugins::DataBags::Config do
  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#map" do
    it "defaults to empty hash" do
      subject.finalize!
      expect(subject.map).to eq(Hash.new)
    end
  end

  describe "#validate" do
    before do
      allow(machine).to receive(:env)
        .and_return(double("env",
          root_path: File.expand_path("..", __FILE__),
        ))

      subject.map = {}
    end

    let(:result) do
      subject.finalize!
      subject.validate(machine)
    end

    let(:errors) { result["DataBags"] }

    context "when map is not a hash" do
      before {
        subject.map = "dummy"
      }

      it "returns an error" do
        subject.finalize!
        expect(errors).to include("Data bag map configuration is expected to be a hash!")
      end
    end

    context "when an event has non-lambda configuration" do
      before {
        subject.map = {
            :aws_opsworks_app => "dummy"
        }
      }

      it "returns an error" do
        subject.finalize!
        expect(errors).to include("aws_opsworks_app data bag map configuration is expected to be lambda!")
      end
    end

    context "when an event has lambda configuration with 1 parameter" do
      before {
        subject.map = {
            :aws_opsworks_app => lambda {|x| x}
        }
      }

      it "returns an error" do
        subject.finalize!
        expect(errors).to include("aws_opsworks_app data bag map configuration is expected to be lambda with 2 arguments!")
      end
    end
  end
end
