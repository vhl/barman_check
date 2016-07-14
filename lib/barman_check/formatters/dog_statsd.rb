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
require 'statsd'

module BarmanCheck
  module Formatters
    class DogStatsd < Base

      def initialize(parser, thresholds, options)
        @statsd = Statsd.new('localhost', 8125)
        super(parser, thresholds, options)
      end

      def output
        @statsd.batch do |stats|
          tags = @options[:tags] + ["db_name:#{parser.db_name}"]
          stats.gauge('barman.number_backups', parser.num_backups, tags: tags)
          stats.gauge('barman.backup_age', parser.latest_bu_age, tags: tags)
          stats.service_check('barman.status',
                              barman_check.backup_status,
                              message: check_message)
        end
      end

      def check_message
        "Database: #{parser.db_name} #{backup_count_message} #{failed_status_message} #{latest_backup_message}"
      end
      private :check_message

      def backup_count_message
        "Expected #{@thresholds[:bu_count]} backups found #{parser.num_backups}." if barman_check.backup_count_low?
      end
      private :backup_count_message

      def failed_status_message
        "Failing status: #{parser.bad_statuses.join(',')}." if barman_check.bad_status_critical?
      end
      private :failed_status_message

      def latest_backup_message
        "Latest backup failed." if barman_check.recent_backup_failed?
      end
      private :latest_backup_message
    end
  end
end
