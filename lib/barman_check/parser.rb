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
require 'date'
module BarmanCheck
  class Parser
    FAILED = 'FAILED'.freeze
    attr_reader :db_name, :latest_bu_age,
                :num_backups, :bad_statuses,
                :recent_backup_failed

    def initialize(db_check_data, db_backup_list_data)
      @db_check_data = db_check_data
      @db_backups_data = db_backup_list_data
      @recent_backup_failed = false
      @num_backups = 0
      @bad_statuses = []
      @backups = []
      parse_check_data
      parse_backup_list_data
    end

    def parse_check_data
      server_info = @db_check_data.first
      # line looks like this "Server main: ",
      # where main is the db name we want to parse out
      _rest_of_line, server_name_info = server_info.split(' ')
      @db_name, _unwanted_chars = server_name_info.split(':')
      # store anything that reports as failed in the bad status array
      @db_check_data[1..-1].each do |status_line|
        feature, status, _part1, _part2 = status_line.split(':')
        @bad_statuses.push(feature.strip) if status !~ /OK/
      end
    end

    # parses the backup list looking for FAILED backups;
    # sets num_backups; calls method that figures out
    # the age of the most recent backup
    def parse_backup_list_data
      unless @db_backups_data.length == 0
        @db_backups_data.each do |bu_line|
          unless bu_line.include?('FAILED')
            @backups.push(bu_line.split(/(?:^|\W)Size(?:$|\W)*(\d+.\.\d+)/)[1].to_f)
          end
        end
        @num_backups = @backups.size
      end
      determine_backup_age
    end

    # determine age in hours of the most recent backup
    # if there are any. sets recent_backup_failed and
    # latest_backup_age (the latter only if most recent
    # was successful) Precondition: num_backups most have
    # been calculated prior to calling this method
    def determine_backup_age
      if num_backups > 0
        # ensure that the most recent is not a failure
        if @db_backups_data.first.include?(FAILED)
          @recent_backup_failed = true
        else
          _name, datetime_recent_file_string, _throw_away = @db_backups_data.first.split('-')
          datetime_most_recent = DateTime.parse(datetime_recent_file_string)
          # NOTE: barman is reporting file dt with no adjustment for GMT
          # this causes the file dt to look like a UTC date but it is not!
          # so we need to adjust the file datetime to include the offset from GMT
          # of the server that this process and barman are running on. Otherwise
          # the most recent backup is reporting as older than it really is.
          @latest_bu_age = ((DateTime.now.to_time.utc - datetime_most_recent.to_time + DateTime.now.to_time.utc_offset) / 60 / 60).round
        end
      end
    end

    def backups_growing
      if @num_backups == 0
        false
      else
        last_size = 0.0
        backups_growing = true
        @backups.reverse_each do |backup|
          if last_size > backup
            backups_growing = false
            break
          end
          last_size = backup
        end
        backups_growing
      end
    end
  end
end

# rubocop:disable all
#db_check = ["Server main:", "ssh: OK ", "PostgreSQL: OK ", 
#            "archive_mode: OK ",
#            "archive_command:  OK ",
#            "continuous archiving: OK ", 
#            "directories: OK ",
#            "retention policy settings: OK ",
#            "backup maximum age: OK (interval provided: 1 day, latest backup age: 11 hours, 48 minutes) ",
#            "compression settings: OK ",
#            "minimum redundancy requirements: OK (have 3 backups, expected at least 1)"]
#db_list = ["main 20160119T000001 - Tue Jan 19 00:00:49 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB",
#           "main 20160117T000002 - Sun Jan 17 00:00:36 2016 - Size: 27.0 GiB - WAL Size: 68.7 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
#puts "Age of recent backup #{parser.latest_bu_age}"
#Failed backups are in the backups list
#db_list = ["main 20160201T170824 - FAILED",
#           "main 20160201T165546 - Mon Feb  1 16:55:50 2016 - Size: 18.8 MiB - WAL Size: 0 B",
#           "main 20160201T162310 - Mon Feb  1 16:23:13 2016 - Size: 18.8 MiB - WAL Size: 32.4 KiB",
#           "main 20160201T153836 - FAILED",
#           "main 20160129T220754 - FAILED"]
#puts "Run with failed backups in list"
#parser = BarmanCheck::Parser.new(db_check, db_list)
#puts "Recent backup failed? #{parser.recent_backup_failed?}"

# Everything OK except there are less than the desired # of backups
#db_check = ["Server main:", "ssh: OK ", "PostgreSQL: OK ", 
#            "archive_mode: OK ",
#            "archive_command:  OK ",
#            "continuous archiving: OK ", 
#            "directories: OK ",
#            "retention policy settings: OK ",
#            "backup maximum age: OK (interval provided: 1 day, latest backup age: 11 hours, 48 minutes) ",
#            "compression settings: OK ",
#            "minimum redundancy requirements: OK (have 2 backups, expected at least 1)"]
#db_list = ["main 20160119T000001 - Tue Feb  1 00:00:49 2016 - Size: 28.2 GiB - WAL Size: 33.3 MiB",
#           "main 20160118T000001 - Mon Jan 18 00:00:43 2016 - Size: 27.9 GiB - WAL Size: 102.3 MiB"]
#parser = BarmanCheck::Parser.new(db_check, db_list)
# rubocop:enable all
