require 'yaml'
require 'open-uri'
require 'csv'

module Harrier
  class Client

    attr_accessor :options

    OPTION_NAMES = %i(token fields url)

    def initialize(source, options = {})
      self.options = load_schema(source)
        .inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        .merge(options)
      validate_options!
    end

    def load_schema(source)
      if source.is_a?(Hash)
        source
      elsif File.exist?(source)
        YAML.load_file(source)
      else
        YAML.load(open(source).read)
      end
    end

    def csv_options
      options.dup.tap do |opts|
        OPTION_NAMES.each { |key| opts.delete(key) }
      end
    end

    def validate_options!
      OPTION_NAMES.each do |key|
        raise ":#{key} is missing" unless options.key?(key)
      end
    end

    def parse(options = {}, &block)
      raise(ArgumentError, 'No block given') unless block_given?
      options = csv_options.merge(options)
      CSV.new(file, options).each do |row|
        record = build_record(row)
        block.call(record)
      end
    end

    def token
      options[:token]
    end

    def build_record(row)
      { token: token }.tap do |data|
        options[:fields].each do |key, target|
          if target
            data[key.to_sym] = row[target]
          else
            data[key.to_sym] = nil
          end
        end
      end
    end

    def open_file(url)
      puts "Read file at: #{url}"
      open(url, read_timeout: nil)
    end

    def file
      @file ||= begin
        io = open_file(options[:url])
        if encoding = options[:encoding]
          io.read.force_encoding(encoding).encode('utf-8')
        else
          io
        end
      end
    end

  end
end
