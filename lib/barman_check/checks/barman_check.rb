# coding: utf-8
#
# Copyright © 2016 Vista Higher Learning, Inc.
#
# This file is part of barman_check.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module BarmanCheck
  module Checks
    class BarmanCheck
      OK = 0
      WARNING = 1
      CRITICAL = 2
      UNKNOWN = 3

      def initialize(parser, thresholds)
        @parser = parser
        @thresholds = thresholds
      end

      def backup_file_count_check
        num_backups = @parser.num_backups
        if num_backups >= @thresholds[:bu_count]
          OK
        elsif num_backups >= 1
          WARNING
        else CRITICAL
        end
      end

      def backup_age_check
        latest_bu_age = @parser.latest_bu_age
        if latest_bu_age < @thresholds[:bu_age]
          OK
        else
          CRITICAL
        end
      end

      def bad_status_check
        if @parser.bad_statuses.length == 0
          OK
        else
          CRITICAL
        end
      end

      def bad_status_critical?
        bad_status_check == CRITICAL
      end

      def backup_file_count_critical?
        backup_file_count_check == CRITICAL
      end

      def backup_age_check_critical?
        backup_age_check == CRITICAL
      end

      def backup_growth_check
        if @parser.backups_growing
          OK
        else
          CRITICAL
        end
      end

      def recent_backup_failed_check
        if @parser.recent_backup_failed
          CRITICAL
        else
          OK
        end
      end

      def backups?
        @parser.num_backups > 0
      end

      def bu_age_ok?
        @parser.latest_bu_age < @thresholds[:bu_age]
      end

      def backup_growth_ok?
        @parser.backups_growing
      end
      
      def backup_count_low?
        backup_file_count_check > OK
      end
      
      def higher_alert(alert_status)
        bu_file_count_status = backup_file_count_check
        bu_file_count_status > alert_status ? bu_file_count_status : alert_status
      end
      
    end
  end
end

# rubocop:disable all
#require 'barman_check/parser'
#db_check = ["Server main:", "ssh: OK ", "PostgreSQL: OK ", 
#            "archive_mode: OK ",
#            "archive_command:  OK ",
#            "continuous archiving: OK ", 
#            "directories: OK ",
#            "retention policy settings: OK ",
#            "backup maximum age: OK (interval provided: 1 day, latest backup age: 23 hours, 48 minutes) ",
#            "compression settings: OK ",
#            "minimum redundancy requirements: OK (have 3 backups, expected at least 1)"]
#db_list = ["main 20160201T000001 - Mon Feb  1 22:55:50 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB",
#           "main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.0 GiB - WAL Size: 68.7 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#puts " parser results latest backup age: #{parser.latest_bu_age}"
#thresholds = { :bu_count => 3, :bu_age => 25 }
#puts "Input thresholds count #{thresholds[:bu_count]} age #{thresholds[:bu_age]} "
#barman_check = BarmanCheck::Checks::BarmanCheck.new(parser,thresholds)
#puts " Bad status check : #{barman_check.bad_status_check} "
#puts " Backup file count check : #{barman_check.backup_file_count_check} "
#puts " Backup growth check : #{barman_check.backup_growth_check} "
#puts " Backup age check : #{barman_check.backup_age_check} "

# case where 0 < number of backups < desired number of backups
# using same input above, upping backup count in threshold to 4
#parser = BarmanCheck::Parser.new(db_check, db_list)
#puts " parser results latest backup age: #{parser.latest_bu_age}"
#thresholds = { :bu_count => 4, :bu_age => 25 }
#puts "Input thresholds count #{thresholds[:bu_count]} age #{thresholds[:bu_age]} "
#barman_check = BarmanCheck::Checks::BarmanCheck.new(parser,thresholds)
#puts " Bad status check : #{barman_check.bad_status_check} "
#puts " Backup file count check : #{barman_check.backup_file_count_check} "
#puts " Backup growth check : #{barman_check.backup_growth_check} "
#puts " Backup age check : #{barman_check.backup_age_check} "
#
#case where the most recent backup failed
#db_list = ["main 20160201T000001 - FAILED",
#           "main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB",
#           "main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.0 GiB - WAL Size: 68.7 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#puts " parser results latest backup age: #{parser.latest_bu_age}"
#thresholds = { :bu_count => 3, :bu_age => 25 }
#barman_check = BarmanCheck::Checks::BarmanCheck.new(parser,thresholds)
#puts " recent backup failed: #{barman_check.recent_backup_failed_check}"
#puts " have backups?: #{barman_check.have_backups?}"
# rubocop:enable all
