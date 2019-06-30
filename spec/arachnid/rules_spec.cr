require "../spec_helper"

describe Arachnid::Rules do
  it "should create a new Rules object" do
    rules = Arachnid::Rules(String).new
    rules.should_not be_nil
    rules.accept.should be_empty
    rules.reject.should be_empty
  end

  it "should allow values for 'accept' and 'reject' in initializer" do
    accept_proc = ->(string : String) { true  }
    reject_proc = ->(string : String) { false }

    rules = Arachnid::Rules(String).new(accept: [accept_proc], reject: [reject_proc])
    rules.accept.should contain accept_proc
    rules.reject.should contain reject_proc
  end

  describe "#accept?" do



  end

  describe "#reject?" do

  end
end
