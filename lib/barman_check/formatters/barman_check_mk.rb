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

require 'barman_check/checks/barman_check'

module BarmanCheck
  module Formatters
    class BarmanCheckMk
      attr_reader :parser
      
      OK, WARNING, CRITICAL, UNKNOWN = 0, 1, 2, 3 
      STATUS_LOOKUP = { 0 => "OK", 1 => "WARNING", 2 => "CRITICAL"}

      def initialize(parser, thresholds)
        @parser = parser
        @thresholds = thresholds
      end

      def barman_check
        @barman_check ||= BarmanCheck::Checks::BarmanCheck.new(@parser, @thresholds)
      end

      def output
        ''.tap do |s|
          s << backup_status
          s << backup_growth
        end
      end

      def backup_status
        # first check for failed states, in order of importance
        collect_failure_status
        # if we get to here and the status is not CRITICAL we might 
        # need to override it with the WARNING status for backup count
        file_count_status = barman_check.backup_file_count_check
        if file_count_status > OK
          # only change the output status if file count status is higher alert
          if file_count_status > @status
            @status = file_count_status
          end
          # always report expected status for file count
          # when it is CRITICAL or WARNING
          @status_string << "expected #{@thresholds[:bu_count]} backups found #{@parser.num_backups}" 
        else
        # add backup file count
        @status_string << "backups=#{@parser.num_backups}"
        end
        # only report age of backups if there is at least one
        puts "in backup_status num backups #{@parser.num_backups}"
        puts "in backup_status latest backup age #{@parser.latest_bu_age}"
        if @parser.num_backups > 0
          @status_string << " backup_age=#{@parser.latest_bu_age < @thresholds[:bu_age] ? "OK" : @parser.latest_bu_age}"
        end
        "#{@status} Barman_#{@parser.db_name}_status - #{STATUS_LOOKUP[@status]} #{@status_string}\n"
      end
      
      def backup_growth
        growth_status = barman_check.backup_growth_check
        report_string = "#{STATUS_LOOKUP[growth_status]}" 
        if growth_status > OK
          report_string << " bad growth trend"
        end
        "#{growth_status} Barman_#{@parser.db_name}_growth - #{report_string}\n"
      end
      
      def collect_failure_status
        # check for failed states, in order of importance
        @status_string = ""
        @status = OK
        if barman_check.bad_status_check == CRITICAL
          @status = barman_check.bad_status_check
          @status_string = @parser.bad_statuses * ","
          @status_string << " "
        elsif barman_check.backup_file_count_check == CRITICAL
          @status = barman_check.backup_file_count_check
          @status_string = "expected #{@thresholds[:bu_count]} backups found #{@parser.num_backups}" 
        elsif barman_check.backup_age_check == CRITICAL
          @status = barman_check.backup_age_check
        end
      end
      
    end
  end
end

#require 'barman_check/parser'
#db_check = ["Server main:", "ssh: OK ", "PostgreSQL: OK ", 
#            "archive_mode: OK ",
#            "archive_command:  OK ",
#            "continuous archiving: OK ", 
#            "directories: OK ",
#            "retention policy settings: OK ",
#            "backup maximum age: OK (interval provided: 1 day, latest backup age: 11 hours, 48 minutes) ",
#            "compression settings: OK ",
#            "minimum redundancy requirements: OK (have 2 backups, expected at least 1)"]
#db_list = ["main 20160201T000001 - Tue Feb  2 16:55:50 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB",
#           "main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.0 GiB - WAL Size: 68.7 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#parser.determine_backup_age
#thresholds = { :bu_count => 3, :bu_age => 25 }
#check_mk = BarmanCheck::Formatters::BarmanCheckMk.new(parser,thresholds)
#check_mk.barman_check
#puts "Barman check results: \n#{check_mk.output}"

#case where there are 0 < number of backup files < desired number
#db_list = ["main 20160201T000001 - Mon Feb  1 22:55:50 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Sun Jan 31 22:56:52 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#parser.determine_backup_age
##thresholds = { :bu_count => 3, :bu_age => 25 }
#thresholds = { :bu_count => 3, :bu_age => 50 }
#check_mk = BarmanCheck::Formatters::BarmanCheckMk.new(parser,thresholds)
#check_mk.barman_check
#puts "Barman check results: \n#{check_mk.output}"