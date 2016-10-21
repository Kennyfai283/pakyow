require_relative '../support/unit_helper'
require_relative '../../../lib/pakyow/test_help/ext/request'

RSpec.describe Pakyow::Request do
  describe 'params' do
    let :req do
      Pakyow::Request.new(env)
    end

    let :data do
      { 'foo' => 'bar' }
    end

    context 'when env contains pakyow.params' do
      let :env do
        Rack::MockRequest.env_for('/', 'pakyow.params' => data)
      end

      it 'returns pakyow.params' do
        expect(req.params).to be(data)
      end
    end

    context 'when env does not contain pakyow.params' do
      let :env do
        Rack::MockRequest.env_for('/', params: data)
      end

      it 'returns the results of the original params method' do
        expect(req.params).to eq(data)
      end
    end
  end
end
