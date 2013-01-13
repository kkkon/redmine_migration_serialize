# encoding: utf-8
#
# Migration tool for Redmine, ActiveRecord serialize column between ruby1.8 and ruby1.9
#
# Author:  KK.Kon
# License: This source code is released under the MIT license.
#  http://www.opensource.org/licenses/mit-license.php

require 'active_record'
require 'pp'
require 'yaml'

namespace :db do

  desc 'migrate serialize to ruby19 in the database.'
  task :migrate_serialize_to_ruby19 => :environment do
    Convert::connect
    if RUBY_VERSION < '1.9'
      raise "RUBY_VERSION(#{RUBY_VERSION}) lower than 1.9"
    end

    Convert::migrate_to_ruby19
  end

  desc 'migrate serialize to ruby18 in the database.'
  task :migrate_serialize_to_ruby18 => :environment do
    Convert::connect

    if RUBY_VERSION < '1.9'
      raise "RUBY_VERSION(#{RUBY_VERSION}) lower than 1.9"
    end

    Convert::migrate_to_ruby18
  end

  module Convert

    class ConvertYAML
      def self.dump(obj)
        result = nil

        if RUBY_VERSION >= '1.9'
          cur_yamler = YAML::ENGINE.yamler
          YAML::ENGINE.yamler = @@toYamler
          result = YAML::dump(obj)
          YAML::ENGINE.yamler = cur_yamler
        else
          result = YAML::dump(obj)
        end

        result
      end

      def self.load(yaml)
        result = nil

        if RUBY_VERSION >= '1.9'
          cur_yamler = YAML::ENGINE.yamler
          YAML::ENGINE.yamler = @@fromYamler
          result = YAML::load(yaml)
          YAML::ENGINE.yamler = cur_yamler
        else
          result = YAML::load(yaml)
        end

        result
      end

      def self.fromYamler(yaml='syck')
        self.validateYamler(yaml)

        @@fromYamler = yaml
      end

      def self.toYamler(yaml='psych')
        self.validateYamler(yaml)

        @@toYamler = yaml
      end

      def self.validateYamler(yaml)
        case yaml
        when 'syck','psych'
        else
          raise "unknown yamler '#{yaml}'"
        end
      end

    end

    class ConvertCustomField < ActiveRecord::Base
      self.table_name = :custom_fields

      serialize :possible_values, ConvertYAML
    end

    class ConvertQuery < ActiveRecord::Base
      self.table_name = :queries

      serialize :filters, ConvertYAML
      serialize :column_names, ConvertYAML
      serialize :sort_criteria, ConvertYAML #Array
    end

    class ConvertRepository < ActiveRecord::Base
      self.table_name = :repositories

      serialize :extra_info, ConvertYAML
    end

    class ConvertRole < ActiveRecord::Base
      self.table_name = :roles

      serialize :permissions, ConvertYAML #::Role::PermissionsAttributeCoder
    end

    class ConvertUserPreference < ActiveRecord::Base
      self.table_name = :user_preferences

      serialize :others, ConvertYAML
    end

    def self.establish_connection(params)
      constants.each do |const|
        klass = const_get(const)
        next unless klass.respond_to? 'establish_connection'
        klass.establish_connection params
      end
    end

    def self.connect
      config = Rails.configuration.database_configuration
      #p config[Rails.env]
      self.establish_connection(config[Rails.env])
    end

    def self.migrate_to_all
      if ActiveRecord::Migration::table_exists? ConvertCustomField.table_name
        ConvertCustomField.find(:all).each do |cf|
          #p cf
          cf.save!
        end
      end

      if ActiveRecord::Migration::table_exists? ConvertQuery.table_name
        ConvertQuery.find(:all).each do |query|
          #p query
          query.save!
        end
      end

      if ActiveRecord::Migration::table_exists? ConvertRepository.table_name
        ConvertRepository.find(:all).each do |repo|
          #p repo
          repo.save!
        end
      end

      if ActiveRecord::Migration::table_exists? ConvertRole.table_name
        ConvertRole.find(:all).each do |role|
          #p role
          role.save!
        end
      end

      if ActiveRecord::Migration::table_exists? ConvertUserPreference.table_name
        ConvertUserPreference.find(:all).each do |pref|
          #p pref
          pref.save!
        end
      end
    end

    def self.migrate_to_ruby19
      ConvertYAML::fromYamler('syck')
      ConvertYAML::toYamler('psych')

      self.migrate_to_all
    end

    def self.migrate_to_ruby18
      ConvertYAML::fromYamler('psych')
      ConvertYAML::toYamler('syck')

      self.migrate_to_all

    end

  end

end
