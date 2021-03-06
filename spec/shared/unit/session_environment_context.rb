# encoding: utf-8

shared_context 'Session::Environment' do
  let(:object) { described_class.new({ users: users }, Session::Tracker.new) }

  let(:users) {
    relation = TEST_ENV.repository(:test)[:users]
    mapper   = Mapper.build([[:id], [:name]], model: mock_model(:id, :name))
    Relation.new(relation, mapper)
  }
end
