# coding: utf-8
#
# Copyright © 2016 Vista Higher Learning, Inc.
#
# This file is part of passenger_status_check.
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

require 'barman_check/version'
require 'barman_check/parser'
require 'barman_check/formatters/barman_check_mk'

module BarmanCheck
  OK, WARNING, CRITICAL, UNKNOWN = 0, 1, 2, 3
  STATUS_LOOKUP = { OK => 'OK',
                    WARNING => 'WARNING',
                    CRITICAL => 'CRITICAL',
                    UNKNOWN => 'UNKNOWN' }.freeze

  def self.run(formatter_name, thresholds, status_data, list_data, formatter_options = {})
    parser = BarmanCheck::Parser.new(status_data, list_data)
    formatter = formatter_class(formatter_name).new(parser, thresholds, formatter_options)
    formatter.output
  end

  def self.formatter_class(formatter)
    klass = formatter.to_s.split('_').map(&:capitalize).join
    ['BarmanCheck', 'Formatters', klass].inject(Object) do |constant, name|
      constant.const_get(name)
    end
  end
end
