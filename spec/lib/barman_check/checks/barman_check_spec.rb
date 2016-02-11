require 'spec_helper'

describe BarmanCheck::Checks::BarmanCheck do
    let(:thresholds) do
    { bu_count: 3, bu_age: 25 }
    end
    
    describe 'barman check all status levels' do
      before do
        @parser = double(BarmanCheck::Parser)
        @barman_check = described_class.new(@parser, thresholds)
      end
      
      describe 'backup_file_count_check OK' do
        it 'returns 0 (OK) from backup file count check,
            false from backup_file_count_critical?,
            false from backup_count_low?' do
          allow(@parser).to receive(:num_backups) { 3 }
          expect(@barman_check.backup_file_count_check).to eq(BarmanCheck::OK)
          expect(@barman_check.backup_file_count_critical?).to eq(false)
          expect(@barman_check.backup_count_low?).to eq(false)
        end
      end
      
      describe 'backup_file_count_check less than desired number of backups' do
        it 'returns 1 (WARNING) from backup file count check,
            false from backup_file_count_critical?, 
            true from backups?,
            true from backup_count_low?' do
          allow(@parser).to receive(:num_backups) { 2 }
          expect(@barman_check.backup_file_count_check).to eq(BarmanCheck::WARNING)
          expect(@barman_check.backup_file_count_critical?).to eq(false)
          expect(@barman_check.backup_count_low?).to eq(true)
        end
      end
      
      describe 'backup_file_count_check no backups' do
        it 'returns 2 (CRITICAL) from backup file count check, 
            false from backup_file_count_critical?, 
            false from backups?,
            true from backup_count_low' do
          allow(@parser).to receive(:num_backups) { 0 }
          expect(@barman_check.backup_file_count_check).to eq(BarmanCheck::CRITICAL)
          expect(@barman_check.backup_file_count_critical?).to eq(true)
          expect(@barman_check.backups?).to eq(false)
          expect(@barman_check.backup_count_low?).to eq(true)
        end
      end
      
      describe 'backup_age_check OK' do
        it 'returns 0 (OK) from backup age check,
            false from backup_age_critical?,
            true from backup_age_ok' do
          allow(@parser).to receive(:latest_bu_age) { 12 }
          allow(@parser).to receive(:recent_backup_failed) { false }
          expect(@barman_check.backup_age_check).to eq(BarmanCheck::OK)
          expect(@barman_check.backup_age_check_critical?).to eql(false)
          expect(@barman_check.backup_age_ok?).to eql(true)
        end
      end
    
      describe 'backup_age_check backup age equals threshold' do
        it 'returns 0 (OK) from backup age check, 
            false from backup_age_critical?,
            true from backup_age_ok' do
          allow(@parser).to receive(:latest_bu_age) { 25 }
          allow(@parser).to receive(:recent_backup_failed) { false }
          expect(@barman_check.backup_age_check).to eq(BarmanCheck::OK)
          expect(@barman_check.backup_age_check_critical?).to eql(false)
          expect(@barman_check.backup_age_ok?).to eql(true)
        end
      end
    
      describe 'backup_age_check backup too old' do
        it 'returns 2 (CRITICAL) from backup age check, 
            true from backup_age_check_critical?,
            false from backup_age_ok' do
          allow(@parser).to receive(:latest_bu_age) { 26 }
          allow(@parser).to receive(:recent_backup_failed) { false }
          expect(@barman_check.backup_age_check).to eq(BarmanCheck::CRITICAL)
          expect(@barman_check.backup_age_check_critical?).to eql(true)
          expect(@barman_check.backup_age_ok?).to eql(false)
        end
      end
      
      describe 'backup_age_check fails due to recent backup failure' do
        it 'returns true from backup_age_check_critical?' do
          allow(@parser).to receive(:recent_backup_failed) { true }
          expect(@barman_check.backup_age_check_critical?).to eql(true)
        end
      end
      
      describe 'recent_backup_failed returns no failure' do
        it 'returns 0 (OK) from recent_backup_failed_check, 
            false from recent_backup_failed?' do
          allow(@parser).to receive(:recent_backup_failed) { false }
                expect(@barman_check.recent_backup_failed_check).to eq(BarmanCheck::OK)
          expect(@barman_check.recent_backup_failed?).to eql(false)
        end
      end
      describe 'recent_backup_failed returns failure' do
        it 'returns 2 (CRITICAL) from recent_backup_failed_check,
            true from recent_backup_failed?' do
          allow(@parser).to receive(:recent_backup_failed) { true }
          expect(@barman_check.recent_backup_failed_check).to eq(BarmanCheck::CRITICAL)
          expect(@barman_check.recent_backup_failed?).to eql(true)
        end
      end
      
      describe 'bad_status_check barman reports no backups growing' do
        it 'returns 0 (OK) from bad status check,
            false from bad_status_critical?' do
          allow(@parser).to receive(:bad_statuses) { [] }
          expect(@barman_check.bad_status_check).to eq(BarmanCheck::OK)
          expect(@barman_check.bad_status_critical?).to eql(false)
        end
      end
    
      describe 'bad_status_check barman reports failures' do
        it 'returns 2 (CRITICAL) from bad status check,
            true from  bad_status_critical?' do
          allow(@parser).to receive(:bad_statuses) { ['ssh', 'PostgreSQL'] }
          expect(@barman_check.bad_status_check).to eq(BarmanCheck::CRITICAL)
          expect(@barman_check.bad_status_critical?).to eql(true)
        end
      end
      
      describe 'backup_growth_check barman reports no problem' do
        it 'returns 0 (OK) from backup growth check,
            true from backup_growth_ok?' do
          allow(@parser).to receive(:backups_growing) { true }
          expect(@barman_check.backup_growth_check).to eq(BarmanCheck::OK)
          expect(@barman_check.backup_growth_ok?).to eql(true)
        end
      end
    
      describe 'backup_growth_check barman reports bad growth trend' do
        it 'returns 2 (CRITICAL) from backup growth check,
            false from backup_growth_ok?' do
          allow(@parser).to receive(:backups_growing) { false }
          expect(@barman_check.backup_growth_check).to eq(BarmanCheck::CRITICAL)
          expect(@barman_check.backup_growth_ok?).to eql(false)
        end
      end
    end
end
