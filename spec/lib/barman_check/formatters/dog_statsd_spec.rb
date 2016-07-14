require 'spec_helper'

describe BarmanCheck::Formatters::DogStatsd do
  let(:thresholds) { { bu_count: 3, bu_age: 25 } }
  let(:statsd) { double(Statsd).as_null_object }
  let(:expected_backups) { 3 }
  let(:expected_backup_age) { 25 }
  let(:database_name) { 'test_database' }
  let(:parser) { double(BarmanCheck::Parser, num_backups: expected_backups,
                                             db_name: database_name,
                                             latest_bu_age: expected_backup_age,
                                             bad_statuses: [],
                                             recent_backup_failed: false ) }
  let(:formatter) { described_class.new(parser, thresholds, tags: []) }

  before do
    allow(statsd).to receive(:batch).and_yield(statsd)
    allow(Statsd).to receive(:new).and_return(statsd)
  end

  describe '#eutput' do
    context 'metrics' do
      it 'sends number of backups metrics' do
        expect(statsd).to receive(:gauge).with('barman.number_backups', expected_backups, tags: ["db_name:#{database_name}"])
        formatter.output
      end

      it 'sends the latest backup age' do
        expect(statsd).to receive(:gauge).with('barman.backup_age', expected_backup_age, tags: ["db_name:#{database_name}"])
        formatter.output
      end
    end

    context 'check' do
      it 'includes the database name' do
        expect(statsd).to receive(:service_check).with('barman.status',
                                                       BarmanCheck::OK, message: /#{database_name}/)
        formatter.output
      end

      context 'OK' do
        it 'reports an OK status' do
          expect(statsd).to receive(:service_check).with('barman.status',
                                                         BarmanCheck::OK, message: /.*/)
          formatter.output
        end
      end

      context 'WARNING' do
        it 'reports if the backup count is low' do
          low_backups_count = expected_backups - 1
          allow(parser).to receive(:num_backups).and_return(low_backups_count)
          expect(statsd).to receive(:service_check).with('barman.status',
                                                         BarmanCheck::WARNING, message: /Expected #{thresholds[:bu_count]} backups found #{low_backups_count}/)
          formatter.output
        end
      end

      context 'CRITICAL' do
        it 'reports the failed statuses' do
          failed_statuses = ['ssh', 'postgres']
          allow(parser).to receive(:bad_statuses).and_return(failed_statuses)
          expect(statsd).to receive(:service_check).with('barman.status',
                                                         BarmanCheck::CRITICAL, message: /Failing status: #{failed_statuses.join(',')}/)
          formatter.output
        end

        it 'reports if recent backup failed' do
          allow(parser).to receive(:recent_backup_failed).and_return(true)
          expect(statsd).to receive(:service_check).with('barman.status',
                                                         BarmanCheck::CRITICAL, message: /Latest backup failed/)
          formatter.output
        end
      end
    end
  end
end
