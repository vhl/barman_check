require 'spec_helper'
require 'date'

describe BarmanCheck do
  it 'has a version number' do
    expect(BarmanCheck::VERSION).not_to be nil
  end

describe '#check' do
  before do
   # initialize values used by all tests
   @expected_template = '%1$s Barman_main_status - %2$s %3$s backup_age=%4$s
%5$s Barman_main_growth - %6$s'
   @expected_template_no_bu_age = '%1$s Barman_main_status - %2$s %3$s
%4$s Barman_main_growth - %5$s'
   @formatter  = :barman_check_mk
   # set the threshold for age of file reported in test data plus 1 hour
   # that will cause repeatable happy path using the test data files
   test_file_date = DateTime.parse("Tue Jan 26 10:15:49 2016")
   now = DateTime.now
   bu_age_threshold = (((now.to_time - test_file_date.to_time)/60/60).round) + 1
   @thresholds = { bu_count: 3, bu_age: bu_age_threshold }
  end

  context 'given no status failures, correct number of backups and a backup that is not stale' do
    before do
      # open a fixture for the optimal path
      file_path = 'spec/fixtures/barman-check.txt'
      @status_data = File.readlines(file_path)
      file_path = 'spec/fixtures/barman-list.txt'
      @list_data = File.readlines(file_path)
    end
    
    it 'generates the correct output for nagios' do
      #0 Barman_main_status - OK backups=3 backup_age=OK
      #0 Barman_main_growth - OK
      expected = @expected_template % ['0', 'OK', 'backups=3', 'OK', '0', 'OK']
      output = BarmanCheck.run(@formatter, @thresholds, @status_data, @list_data)
      puts "Happy path output \n#{output}"
      expect(output).to match(expected)
    end
  end
  
  context 'less than the desired number of backups, everything else OK' do
  before do
    # open a fixture for the optimal path
    file_path = 'spec/fixtures/barman-check.txt'
    @status_data = File.readlines(file_path)
    file_path = 'spec/fixtures/barman-list.txt'
    @list_data = File.readlines(file_path) 
  end

  it 'generates the correct output for nagios' do 
    #1 Barman_main_status - WARNING expected 4 backups found 3 backup_age=OK
    #0 Barman_main_growth - OK
    expected = @expected_template % ['1', 'WARNING', 'expected 4 backups found 3', 'OK', '0', 'OK']
    test_thresholds = { bu_count: 4, bu_age: @thresholds[:bu_age] }
    output = BarmanCheck.run(@formatter, test_thresholds, @status_data, @list_data)
    puts "Too few backups output:\n#{output}"
    expect(output).to match(expected)
  end
end

  context 'latest backup too old, everything else OK' do
    before do
      # open a fixture for the optimal path
      file_path = 'spec/fixtures/barman-check.txt'
      @status_data = File.readlines(file_path)
      file_path = 'spec/fixtures/barman-list.txt'
      @list_data = File.readlines(file_path) 
    end

    it 'generates the correct output for nagios' do
      # expected output to match age of recent file
      expected_output_age = @thresholds[:bu_age] - 1 
      #expected = "2 Barman_main_status - CRITICAL backups=3 backup_age=#{expected_output_age}
      #0 Barman_main_growth - OK"
      expected = @expected_template % ['2', 'CRITICAL', 'backups=3', expected_output_age, '0', 'OK']    
      test_thresholds = { bu_count: 3, bu_age: 25 }
      output = BarmanCheck.run(@formatter, test_thresholds, @status_data, @list_data)
      puts "Latest backup too old output:\n#{output}"
      expect(output).to match(expected)
    end
  end

  context 'bad growth trend, everything else OK' do
    before do
      # open a fixture for the optimal path
      file_path = 'spec/fixtures/barman-check.txt'
      @status_data = File.readlines(file_path)
      file_path = 'spec/fixtures/barman-list-bad-growth.txt'
      @list_data = File.readlines(file_path) 
    end

    it 'generates the correct output for nagios' do
      # expected output to match age of recent file
      expected_output_age = @thresholds[:bu_age] - 1 
      #expected = "0 Barman_main_status - OK backups=3 backup_age=OK
      #2 Barman_main_growth - CRITICAL bad growth trend"
      expected = @expected_template % ['0', 'OK', 'backups=3', 'OK', '2', 'CRITICAL bad growth trend']
      output = BarmanCheck.run(@formatter, @thresholds, @status_data, @list_data)
      puts "Latest backup too old output:\n#{output}"
      expect(output).to match(expected)
    end
  end
  
  context 'no backups, can\'t report growth trend, everything else OK' do
    before do
      # open a fixture for the optimal path
      file_path = 'spec/fixtures/barman-check-no-backups.txt'
      @status_data = File.readlines(file_path)
      file_path = 'spec/fixtures/barman-list-empty.txt'
      @list_data = File.readlines(file_path) 
    end

    it 'generates the correct output for nagios' do
      #expected = "2 Barman_main_status - CRITICAL minimum redundancy requirements expected 3 backups found 0
      #2 Barman_main_growth - CRITICAL bad growth trend
      expected = @expected_template_no_bu_age % ['2', 'CRITICAL', 'minimum redundancy requirements expected 3 backups found 0', '2', 'CRITICAL bad growth trend']
      output = BarmanCheck.run(@formatter, @thresholds, @status_data, @list_data)
      puts "Latest backup too old output:\n#{output}"
      expect(output).to match(expected)
    end
  end
  
   #2 Barman_main_status - CRITICAL ssh,PostgreSQL backups=3 backup_age=OK
   #2 Barman_main_growth - OK
   context 'status failures reported, but have correct number of backups and a backup that is not stale' do
    before do
      # open a fixture for the optimal path
      file_path = 'spec/fixtures/barman-check-failure.txt'
      @status_data = File.readlines(file_path)
      file_path = 'spec/fixtures/barman-list.txt'
      @list_data = File.readlines(file_path)
    end
    
    it 'generates the correct output for nagios' do
      #0 Barman_main_status - OK backups=3 backup_age=OK
      #0 Barman_main_growth - OK
      expected = @expected_template % ['0', 'OK', 'backups=3', 'OK', '0', 'OK']
      output = BarmanCheck.run(@formatter, @thresholds, @status_data, @list_data)
      puts "Happy path output \n#{output}"
      expect(output).to match(expected)
    end
  end
end
end
