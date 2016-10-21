require 'pakyow/support/aargv'

RSpec.describe Pakyow::Aargv do

  it "names args" do
    v1 = 'foo'
    v2 = :bar

    expected_ret = {
      str: v1,
      sym: v2,
    }

    expect(described_class.normalize([v1, v2], str: String, sym: Symbol)).to eq(expected_ret)
    expect(described_class.normalize([v2, v1], str: String, sym: Symbol)).to eq(expected_ret)
  end

  it "mixes in default values" do
    v1 = 'foo'
    v2 = :bar

    expected_ret = {
      str: v1,
      sym: v2,
    }

    expect(described_class.normalize([v1], str: String, sym: [Symbol, v2])).to eq(expected_ret)
  end

  it "respects real values when default" do
    v1 = 'foo'
    v2 = :bar

    expected_ret = {
      str: v1,
      sym: v2,
    }

    expect(described_class.normalize([v1, v2], str: String, sym: [Symbol, :def])).to eq(expected_ret)
  end

  it "ignores values when no default" do
    v1 = 'foo'

    expected_ret = {
      str: v1
    }

    expect(described_class.normalize([v1], str: String, sym: Symbol)).to eq(expected_ret)
  end

end
