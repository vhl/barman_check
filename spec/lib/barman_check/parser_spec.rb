require 'spec_helper'

describe BarmanCheck::Parser do
  describe 'barman reports all OK' do
    before do
      check_data = ['Server main:', 'ssh: OK ', 'PostgreSQL: OK ',
                    'archive_mode: OK ',
                    'archive_command:  OK ',
                    'continuous archiving: OK ',
                    'directories: OK ',
                    'retention policy settings: OK ',
                    'backup maximum age: OK (interval provided: 1 day, latest backup age: 11 hours, 48 minutes) ',
                    'compression settings: OK ',
                    'minimum redundancy requirements: OK (have 3 backups, expected at least 1)']
      list_data = ['main 20160119T000001 - Tue Jan 19 00:00:49 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB',
                   'main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB',
                   'main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.0 GiB - WAL Size: 68.7 MiB']
      @parser = described_class.new(check_data, list_data)
    end

    describe '#num_backups' do
      it 'returns the number of backups in the backup list' do
        expect(@parser.num_backups).to eq(3)
      end
    end

    describe '#recent_backup_failed' do
      it 'returns whether or not the most recent backup failed ' do
        expect(@parser.recent_backup_failed).to eq(false)
      end
    end

    describe '#db_name' do
      it 'returns the name of the db from the check info' do
        expect(@parser.db_name).to eql('main')
      end
    end

    describe '#bad_statuses' do
      it 'returns the number of activities reporting bad statuses' do
        expect(@parser.bad_statuses.length).to eq(0)
      end
    end

    describe '#backups_growing' do
      it 'returns whether or not backups are growing in size' do
        expect(@parser.backups_growing).to eq(true)
      end
    end
    
    describe '#latest_bu_age' do
      it 'returns latest backup age' do
        expect(@parser.latest_bu_age).to be > 0
      end
    end
  end

  describe 'barman reports most recent backup failures' do
    before do
      check_data = ['Server main:', 'ssh: FAILED (return code: 255) ', 'PostgreSQL: OK ',
                    'archive_mode: OK ',
                    'archive_command:  OK ',
                    'continuous archiving: OK ',
                    'directories: OK ',
                    'retention policy settings: OK ',
                    'backup maximum age: FAILED (interval provided: 1 day, latest backup age: 28 hours, 15 minutes) ',
                    'compression settings: OK ',
                    'minimum redundancy requirements: OK (have 3 backups, expected at least 1)']
      list_data = ['main 20160201T170824 - FAILED',
                   'main 20160201T165546 - Mon Feb  1 16:55:50 2016 - Size: 18.8 MiB - WAL Size: 0 B',
                   'main 20160201T162310 - Mon Feb  1 16:23:13 2016 - Size: 18.8 MiB - WAL Size: 32.4 KiB',
                   'main 20160201T153836 - FAILED',
                   'main 20160129T220754 - FAILED']
      @parser = described_class.new(check_data, list_data)
    end

    describe '#num_backups is less than 3' do
      it 'returns the number of backups in the backup list' do
        expect(@parser.num_backups).to eql(2)
      end
    end

    describe '#recent_backup_failed is true' do
      it 'returns whether or not the most recent backup failed ' do
        expect(@parser.recent_backup_failed).to eq(true)
      end
    end

    describe '#bad_statuses reporting > 0' do
      it 'returns the number of activities reporting bad statuses' do
        expect(@parser.bad_statuses.length).to eq(2)
      end
    end
  end

  describe 'barman reports backups too old and not growing' do
    before do
      check_data = ['Server main:', 'ssh: OK ', 'PostgreSQL: OK ',
                    'archive_mode: OK ',
                    'archive_command:  OK ',
                    'continuous archiving: OK ',
                    'directories: OK ',
                    'retention policy settings: OK ',
                    'backup maximum age: FAILED (interval provided: 1 day, latest backup age: 28 hours, 15 minutes) ',
                    'compression settings: OK ',
                    'minimum redundancy requirements: OK (have 3 backups, expected at least 1)']
      list_data = ['main 20160119T000001 - Tue Jan 26 10:15:49 2016 - Size: 22.2 GiB - WAL Size: 33.3 MiB',
                   'main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB',
                   'main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.0 GiB - WAL Size: 68.7 MiB']

      @parser = described_class.new(check_data, list_data)
    end

    describe '#latest_bu_age > 25 hours' do
      it 'returns whether or latest backup age is > 25 hours' do
        expect(@parser.latest_bu_age).to be > 25
      end
    end

    describe '#backups_growing is false' do
      it 'returns whether or not backups are growing in size' do
        expect(@parser.backups_growing).to eq(false)
      end
    end
  end
  
  describe 'barman reports no backups' do
    before do
      check_data = ['Server main:', 'ssh: OK ', 'PostgreSQL: OK ',
                    'archive_mode: OK ',
                    'archive_command:  OK ',
                    'continuous archiving: OK ',
                    'directories: OK ',
                    'retention policy settings: OK ',
                    'compression settings: OK ',
                    'minimum redundancy requirements: FAILED (have 0 backups, expected at least 1)']
      list_data = ['main 20160119T000001 - FAILED',
                   'main 20160118T000001 - FAILED',
                   'main 20160117T000002 - FAILED']

      @parser = described_class.new(check_data, list_data)
    end

    describe '#num_backups is 0' do
      it 'returns the number of backups in the backup list' do
        expect(@parser.num_backups).to eql(0)
      end
    end
    
    describe '#backups_growing is false' do
      it 'returns whether or not backups are growing in size' do
        expect(@parser.backups_growing).to eq(false)
      end
    end
  end
end
