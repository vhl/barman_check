require 'spec_helper'

describe BarmanCheck::Formatters::BarmanCheckMk do
  let(:thresholds) do
    { bu_count: 3, bu_age: 25 }
  end

  let(:parser) do
    double(BarmanCheck::Parser)
  end

  let(:backup_status) do
    double(BarmanCheck::Formatters::BarmanCheckMk::BackupStatus)
  end

  let(:backup_growth) do
    double(BarmanCheck::Formatters::BarmanCheckMk::BackupGrowth)
  end

  let(:barman_check_mk) do
    described_class.new(parser, thresholds)
  end

  describe 'barman_check_mk produces correct check_mk (Nagios) format' do
    before do
      allow(barman_check_mk).to receive(:backup_status) { backup_status }
      allow(barman_check_mk).to receive(:backup_growth) { backup_growth }
    end

    describe 'barman_check_mk reports all OK' do
      it 'returns string indicating that Barman_db_status and Barman_db_growth are OK' do
        allow(backup_status).to receive(:to_s).and_return("0 Barman_testdb_status - OK backups=3 backup_age=OK\n")
        allow(backup_growth).to receive(:to_s).and_return('0 Barman_testdb_growth - OK')
        expect(barman_check_mk.output).to eql("0 Barman_testdb_status - OK backups=3 backup_age=OK\n0 Barman_testdb_growth - OK")
      end
    end
  end
end

describe BarmanCheck::Formatters::BarmanCheckMk::BackupStatus do
  let(:thresholds) do
    { bu_count: 3, bu_age: 25 }
  end

  let(:parser) do
    double(BarmanCheck::Parser)
  end

  let(:barman_check_mk) do
    double(BarmanCheck::Formatters::BarmanCheckMk)
  end

  let(:barman_check) do
    double(BarmanCheck::Checks::BarmanCheck)
  end

  let(:backup_status) do
    described_class.new(barman_check_mk, barman_check)
  end

  describe 'backup status produces correct check_mk (Nagios) format in all cases' do
    before do
      allow(barman_check_mk).to receive(:parser).and_return(parser)
      allow(barman_check_mk).to receive(:thresholds).and_return(bu_count: 3, bu_age: 25)
    end

    describe 'backup status returns all OK' do
      it 'returns string indicating that Barman_db_status is all OK' do
        allow(parser).to receive(:num_backups) { 3 }
        allow(parser).to receive(:latest_backup_age) { 23 }
        allow(parser).to receive(:recent_backup_failed) { false }
        allow(parser).to receive(:db_name) { 'testdb' }
        allow(parser).to receive(:bad_statuses) { [] }
        allow(barman_check).to receive(:backup_count_low?).and_return(false)
        allow(barman_check).to receive(:backups?).and_return(true)
        allow(barman_check).to receive(:recent_backup_failed?).and_return(false)
        allow(barman_check).to receive(:backup_file_count_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_ok?).and_return(true)
        allow(barman_check).to receive(:backup_age_check_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_check).and_return(BarmanCheck::OK)
        allow(barman_check).to receive(:bad_status_critical?).and_return(false)
        expect(backup_status.to_s).to eql("0 Barman_testdb_status - OK backups=3 backup_age=OK\n")
      end
    end

    describe 'backup status returns status when less than expected # of backups found' do
      it 'returns string indicating that Barman_db_status is too few backups' do
        allow(parser).to receive(:num_backups) { 2 }
        allow(parser).to receive(:recent_backup_failed) { false }
        allow(parser).to receive(:db_name) { 'testdb' }
        allow(parser).to receive(:bad_statuses) { [] }
        allow(barman_check).to receive(:backup_count_low?).and_return(true)
        allow(barman_check).to receive(:backups?).and_return(true)
        allow(barman_check).to receive(:recent_backup_failed?).and_return(false)
        allow(barman_check).to receive(:backup_file_count_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_ok?).and_return(true)
        allow(barman_check).to receive(:backup_age_check_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_check).and_return(BarmanCheck::OK)
        allow(barman_check).to receive(:bad_status_critical?).and_return(false)
        expect(backup_status.to_s).to eql("1 Barman_testdb_status - WARNING expected 3 backups found 2 backup_age=OK\n")
      end
    end

    describe 'backup status returns status when latest backup too old, all the rest OK' do
      it 'returns string indicating that Barman_db_status is backup too old' do
        allow(parser).to receive(:num_backups) { 3 }
        allow(parser).to receive(:latest_bu_age).and_return(30)
        allow(parser).to receive(:recent_backup_failed) { false }
        allow(parser).to receive(:db_name) { 'testdb' }
        allow(parser).to receive(:bad_statuses) { [] }
        allow(barman_check).to receive(:backup_count_low?).and_return(false)
        allow(barman_check).to receive(:backups?).and_return(true)
        allow(barman_check).to receive(:recent_backup_failed?).and_return(false)
        allow(barman_check).to receive(:backup_file_count_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_ok?).and_return(false)
        allow(barman_check).to receive(:backup_age_check_critical?).and_return(true)
        allow(barman_check).to receive(:backup_age_check).and_return(BarmanCheck::CRITICAL)
        allow(barman_check).to receive(:bad_status_critical?).and_return(false)
        expect(backup_status.to_s).to eql("2 Barman_testdb_status - CRITICAL backups=3 backup_age=30\n")
      end
    end

    describe 'backup status returns status when latest backup failed' do
      it 'returns string indicating that Barman_db_status most recent backup failed' do
        allow(parser).to receive(:num_backups) { 3 }
        allow(parser).to receive(:latest_bu_age).and_return(23)
        allow(parser).to receive(:recent_backup_failed) { true }
        allow(parser).to receive(:db_name) { 'testdb' }
        allow(parser).to receive(:bad_statuses) { [] }
        allow(barman_check).to receive(:backup_count_low?).and_return(false)
        allow(barman_check).to receive(:backups?).and_return(true)
        allow(barman_check).to receive(:recent_backup_failed?).and_return(true)
        allow(barman_check).to receive(:backup_file_count_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_ok?).and_return(true)
        allow(barman_check).to receive(:backup_age_check_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_check).and_return(BarmanCheck::OK)
        allow(barman_check).to receive(:bad_status_critical?).and_return(false)
        expect(backup_status.to_s).to eql("2 Barman_testdb_status - CRITICAL backups=3 backup_age=latest backup failed\n")
      end
    end

    describe 'backup status returns status when there are no backups' do
      it 'returns string indicating that Barman_db_status is no backups' do
        allow(parser).to receive(:num_backups) { 0 }
        allow(parser).to receive(:db_name) { 'testdb' }
        allow(barman_check).to receive(:backup_count_low?).and_return(true)
        allow(barman_check).to receive(:backups?).and_return(false)
        allow(barman_check).to receive(:recent_backup_failed?).and_return(false)
        allow(barman_check).to receive(:backup_file_count_critical?).and_return(true)
        allow(barman_check).to receive(:bad_status_critical?).and_return(false)
        expect(backup_status.to_s).to eql("2 Barman_testdb_status - CRITICAL expected 3 backups found 0 \n")
      end
    end

    describe 'backup status returns status when failures reported' do
      it 'returns string indicating that Barman_db_status has failures' do
        allow(parser).to receive(:num_backups) { 3 }
        allow(parser).to receive(:latest_bu_age).and_return(23)
        allow(parser).to receive(:recent_backup_failed) { true }
        allow(parser).to receive(:db_name) { 'testdb' }
        allow(parser).to receive(:bad_statuses) { ['ssh', 'PostgreSQL'] }
        allow(barman_check).to receive(:backup_count_low?).and_return(false)
        allow(barman_check).to receive(:backups?).and_return(true)
        allow(barman_check).to receive(:recent_backup_failed?).and_return(false)
        allow(barman_check).to receive(:backup_file_count_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_ok?).and_return(true)
        allow(barman_check).to receive(:backup_age_check_critical?).and_return(false)
        allow(barman_check).to receive(:backup_age_check).and_return(BarmanCheck::OK)
        allow(barman_check).to receive(:bad_status_critical?).and_return(true)
        expect(backup_status.to_s).to eql("2 Barman_testdb_status - CRITICAL ssh,PostgreSQL backups=3 backup_age=OK\n")
      end
    end
  end
end

describe BarmanCheck::Formatters::BarmanCheckMk::BackupGrowth do
  let(:parser) do
    double(BarmanCheck::Parser)
  end

  let(:barman_check_mk) do
    double(BarmanCheck::Formatters::BarmanCheckMk)
  end

  let(:barman_check) do
    double(BarmanCheck::Checks::BarmanCheck)
  end

  let(:backup_growth) do
    described_class.new(barman_check_mk, barman_check)
  end

  describe 'backup growth produces correct check_mk (Nagios) format for all OK' do
    before do
      allow(barman_check_mk).to receive(:parser).and_return(parser)
    end

    describe 'backup growth reports all OK' do
      it 'returns string indicating that Barman_db_growth is OK' do
        allow(parser).to receive(:db_name) { 'testdb' }
        allow(barman_check).to receive(:backup_growth_ok?).and_return(true)
        allow(barman_check).to receive(:backup_growth_check).and_return(BarmanCheck::OK)
        expect(backup_growth.to_s).to eql('0 Barman_testdb_growth - OK')
      end
    end

    describe 'backup growth returns growth failure' do
      it 'returns string indicating that Barman_db_growth has bad growth trend' do
        allow(parser).to receive(:db_name) { 'testdb' }
        allow(barman_check).to receive(:backup_growth_ok?).and_return(false)
        allow(barman_check).to receive(:backup_growth_check).and_return(BarmanCheck::CRITICAL)
        expect(backup_growth.to_s).to eql('2 Barman_testdb_growth - CRITICAL bad growth trend')
      end
    end
  end
end
