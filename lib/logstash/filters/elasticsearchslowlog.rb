# frozen_string_literal: true

require "logstash/filters/base"
require "json"
require "deepsort"

class LogStash::Filters::Elasticsearchslowlog < LogStash::Filters::Base
  #
  # filter {
  #   elasticsearchslowlog {
  #   }
  # }
  #
  config_name "elasticsearchslowlog"

  # The field to perform filter
  #
  # Example, to use the @message field (default) :
  # [source,ruby]
  #     filter { elasticsearchslowlog { source => "message" } }
  config :source, validate: :string, default: "message"

  def register
    # Add instance variables
  end

  SLOWLOG_REGEX = /^\s*\[(?<local_timestamp>[^,]+),\d+\]\s*\[(?<level>.+?)\s*\]\s*\[index.search.slowlog.(?:query|fetch)\]\s*\[(?<node>.+?)\]\s*\[(?<index>.+?)\]\s*\[(?<shard>.+?)\]\s*(?<key_values>.+)$/.freeze

  def filter(event)
    message = event.get(@source)
    if message
      if matches = message.match(SLOWLOG_REGEX)
        captures = matches.named_captures
        captures.each do |key, value|
          next if key == 'key_values'

          if ['shard'].include?(key)
            value = value.to_i
          end
          event.set(key, value)
        end
        if captures['key_values']
          key_values = parse_key_values(captures['key_values'])
          key_values.each do |key, value|
            if ['took_millis', 'total_shards'].include?(key)
              value = value.to_i
            end
            event.set(key, value)
          end

          source = key_values['source']
          if source
            normalized = normalize_source(source)
            if normalized
              normalized = JSON.dump(normalized)
              source_id = Digest::MD5.hexdigest(normalized)[0..8]
              event.set('source_normalized', normalized)
              event.set('source_id', source_id)
            end
          end
        end
      end
    end

    filter_matched(event)
  end

  private

  def parse_key_values(kv)
    state = :name
    result = {}
    name_start = 0
    value_start = 0
    open_brackets = 0
    name = nil
    pos = 0
    while pos < kv.length
      char = kv[pos]
      case state
      when :name
        if char == '['
          name = kv[name_start..pos - 1]
          value_start = pos + 1
          state = :value
        end
      when :value
        if char == ']' && open_brackets.zero?
          result[name] = kv[value_start..pos - 1]
          pos += 2
          state = :name
          name_start = pos + 1
        elsif char == ']'
          open_brackets -= 1
        elsif char == '['
          open_brackets += 1
        end
      end
      pos += 1
    end
    result
  end

  def normalize_source(source)
    source = JSON.parse(source)
    source.delete("from")
    source.delete("size")
    clean_params(source["query"])
    clean_params(source["aggregations"])
    source.deep_sort
  rescue JSON::ParserError
    nil
  end

  def clean_params(query)
    if query.is_a?(Array)
      query.each { |q| clean_params(q) }
    elsif query.is_a?(Hash)
      if query.key?('term')
        delete_path(query, ['term', '*', 'value'])
      elsif query.key?('terms')
        delete_path(query, ['terms', '*'])
      elsif query.key?('wildcard')
        delete_path(query, ['wildcard', '*', 'wildcard'])
      elsif query.key?('range')
        delete_path(query, ['range', '*', 'from'])
        delete_path(query, ['range', '*', 'to'])
      elsif query.key?('match')
        delete_path(query, ['match', '*', 'query'])
      elsif query.key?('exists')
        delete_path(query, ['exists', 'field'])
      elsif query.key?('date_histogram')
        delete_path(query, ['date_histogram', 'extended_bounds', 'max'])
        delete_path(query, ['date_histogram', 'extended_bounds', 'min'])
      elsif query.key?('prefix')
        delete_path(query, ['prefix', '*', 'value'])
      elsif query.key?('regexp')
        delete_path(query, ['regexp', '*', 'value'])
      elsif query.key?('fuzzy')
        delete_path(query, ['fuzzy', '*', 'value'])
      elsif query.key?('ids')
        delete_path(query, ['ids', 'values'])
      elsif query.key?('parent_id')
        delete_path(query, ['parent_id', 'id'])
      end
      query.each { |_k, v| clean_params(v) }
    end
  end

  def delete_path(object, path)
    if !path.empty? && object
      head, *tail = path
      if !tail.empty? && head == "*"
        if object.is_a?(Array)
          object.each { |v| delete_path(v, tail) }
        elsif object.is_a?(Hash)
          object.each { |_k, v| delete_path(v, tail) }
        end
      elsif tail.empty? && head == "*"
        if object.is_a?(Hash)
          object.each { |k, _v| object[k] = "?" }
        end
      elsif !tail.empty? && object.is_a?(Hash)
        delete_path(object[head], tail)
      elsif tail.empty? && object.is_a?(Hash)
        object[head] = "?"
      end
    end
  end
end
