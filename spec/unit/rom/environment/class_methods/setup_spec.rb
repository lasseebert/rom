# encoding: utf-8

require 'spec_helper'

describe Environment, '.setup' do
  subject { described_class.setup(config).finalize }

  context 'when a repository config hash is passed' do
    let(:config) { { name => uri } }
    let(:name)   { :test }
    let(:uri)    { 'memory://test' }

    let(:coerced_config) { Hash[test: Repository.build(name, coerced_uri)] }
    let(:coerced_uri)    { Addressable::URI.parse(uri) }

    its(:repositories) { should eql(described_class.new(coerced_config, {}, {}, {}).repositories) }
  end
end
