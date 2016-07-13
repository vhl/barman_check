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

require_relative './base'

module BarmanCheck
  module Formatters
    class BarmanCheckMk < Base
      def backup_status
        @backup_status ||= BackupStatus.new(self, barman_check)
      end

      def backup_growth
        @backup_growth ||= BackupGrowth.new(self, barman_check)
      end

      def output
        ''.tap do |s|
          s << backup_status.to_s
          s << backup_growth.to_s
        end
      end

      class BackupStatus
        def initialize(formatter, barman_check)
          @parser = formatter.parser
          @thresholds = formatter.thresholds
          @barman_check = barman_check
        end

        def file_count_status
          if @barman_check.backup_count_low?
            "expected #{@thresholds[:bu_count]} backups found #{@parser.num_backups}"
          else
            "backups=#{@parser.num_backups}"
          end
        end

        def backup_age_status
          if @barman_check.backups? && !@barman_check.recent_backup_failed?
            "backup_age=#{@barman_check.backup_age_ok? ? 'OK' : @parser.latest_bu_age}"
          elsif @barman_check.recent_backup_failed?
            'backup_age=latest backup failed'
          else
            ''
          end
        end

        def failed_statuses
          if @barman_check.bad_status_critical?
            @parser.bad_statuses * ',' << ' '
          else
            ''
          end
        end

        def to_s
          final_status = @barman_check.backup_status
          "#{final_status} Barman_#{@parser.db_name}_status - #{BarmanCheck::STATUS_LOOKUP[final_status]} #{failed_statuses}#{[file_count_status, backup_age_status].join(' ')}\n"
        end
      end

      class BackupGrowth
        def initialize(formatter, barman_check)
          @parser = formatter.parser
          @barman_check = barman_check
        end

        def to_s
          growth_status = @barman_check.backup_growth_check
          growth_report = "#{BarmanCheck::STATUS_LOOKUP[growth_status]}"
          growth_report << ' bad growth trend' unless @barman_check.backup_growth_ok?
          "#{growth_status} Barman_#{@parser.db_name}_growth - #{growth_report}"
        end
      end
    end
  end
end

#rubocop:disable all
# TEST 1 everything OK
# require 'barman_check/parser'
# db_check = ["Server main:", "ssh: OK ", "PostgreSQL: OK ",
#            "archive_mode: OK ",
#            "archive_command:  OK ",
#            "continuous archiving: OK ",
#            "directories: OK ",
#            "retention policy settings: OK ",
#            "backup maximum age: OK (interval provided: 1 day, latest backup age: 11 hours, 48 minutes) ",
#            "compression settings: OK ",
#            "minimum redundancy requirements: OK (have 2 backups, expected at least 1)"]
#db_list = ["main 20160201T000001 - Mon Feb  8 16:55:50 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB",
#           "main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.0 GiB - WAL Size: 68.7 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#thresholds = { :bu_count => 3, :bu_age => 25 }
#check_mk = BarmanCheck::Formatters::BarmanCheckMk.new(parser, thresholds)
#check_mk.barman_check
#puts "Barman check results: \n#{check_mk.output}"

# TEST 2 use same db_check as above: case where there are 0 < number of backup files < desired number
#db_list = ["main 20160201T000001 - Mon Feb  1 22:55:50 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Sun Jan 31 22:56:52 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#thresholds = { :bu_count => 3, :bu_age => 25 }
#thresholds = { :bu_count => 3, :bu_age => 500 }
#check_mk = BarmanCheck::Formatters::BarmanCheckMk.new(parser,thresholds)
#check_mk.barman_check
#puts "Barman check results: \n#{check_mk.output}"

# TEST 3 use same db_check as above: case where the backups are not growing, everything else OK
#db_list = ["main 20160201T000001 - Mon Feb  8 16:55:50 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.0 GiB - WAL Size: 102.3 MiB",
#           "main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.9 GiB - WAL Size: 68.7 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#thresholds = { :bu_count => 3, :bu_age => 200 }
#check_mk = BarmanCheck::Formatters::BarmanCheckMk.new(parser, thresholds)
#check_mk.barman_check
#puts "Barman check results: \n#{check_mk.output}"
# TEST 4 case where we have failed statuses but everything else is OK
#db_check = ["Server main:", "ssh: FAILED ", "PostgreSQL: FAILED ",
#            "archive_mode: OK ",
#            "archive_command:  OK ",
#            "continuous archiving: OK ",
#            "directories: OK ",
#            "retention policy settings: OK ",
#            "backup maximum age: OK (interval provided: 1 day, latest backup age: 11 hours, 48 minutes) ",
#            "compression settings: OK ",
#            "minimum redundancy requirements: OK (have 2 backups, expected at least 1)"]
#db_list = ["main 20160201T000001 - Mon Feb  8 16:55:50 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB",
#           "main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.0 GiB - WAL Size: 68.7 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#thresholds = { :bu_count => 3, :bu_age => 25 }
#check_mk = BarmanCheck::Formatters::BarmanCheckMk.new(parser, thresholds)
#check_mk.barman_check
#puts "Barman check results: \n#{check_mk.output}"
# rubocop:enable all
