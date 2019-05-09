# encoding: utf-8
require_relative '../spec_helper'
require "logstash/filters/elasticsearchslowlog"

describe LogStash::Filters::Elasticsearchslowlog do
  let(:config) do <<-CONFIG
      filter {
        elasticsearchslowlog {
        }
      }
    CONFIG
  end


  describe "filter" do
    sample("message" => "some text") do
      expect(event_get(subject, 'message')).to eq('some text')
    end

    sample("message" => '[2019-05-07T15:27:34,422][TRACE ][index.search.slowlog.query] [elasticsearch-data7.mid.veritrans.co.id] [transactionsv3_2018-12][2] took[350.9ms], took_millis[350], types[transaction], stats[], search_type[QUERY_THEN_FETCH], total_shards[111], source[{"from":0,"size":20,"query":{"bool":{"filter":[{"terms":{"transaction.merchant_id":["abcd"],"boost":1.0}}],"disable_coord":false,"adjust_pure_negative":true,"boost":1.0}},"sort":[{"transaction.transaction_time":{"order":"desc"}}]}],') do
      expect(event_get(subject, 'local_timestamp')).to eq('2019-05-07T15:27:34')
      expect(event_get(subject, 'level')).to eq('TRACE')
      expect(event_get(subject, 'node')).to eq('elasticsearch-data7.mid.veritrans.co.id')
      expect(event_get(subject, 'index')).to eq('transactionsv3_2018-12')
      expect(event_get(subject, 'shard')).to eq(2)
      expect(event_get(subject, 'took_millis')).to eq(350)
      expect(event_get(subject, 'types')).to eq('transaction')
      expect(event_get(subject, 'search_type')).to eq('QUERY_THEN_FETCH')
      expect(event_get(subject, 'total_shards')).to eq(111)
      expect(event_get(subject, 'source')).to eq('{"from":0,"size":20,"query":{"bool":{"filter":[{"terms":{"transaction.merchant_id":["abcd"],"boost":1.0}}],"disable_coord":false,"adjust_pure_negative":true,"boost":1.0}},"sort":[{"transaction.transaction_time":{"order":"desc"}}]}')
      expect(subject).to include('source_id')
    end
  end

  messages = IO.read(File.join(File.dirname(__FILE__), 'fixture_valid.txt')).split("\n")
  source_normalized = IO.read(File.join(File.dirname(__FILE__), 'fixture_source_normalized.txt')).split("\n")
  messages.each_with_index do |message, i|
    describe "fixtures_valid #{i}" do
      sample('message' => message) do
        expect(subject).to include('message')
        expect(subject).to include('local_timestamp')
        expect(subject).to include('level')
        expect(subject).to include('node')
        expect(subject).to include('index')
        expect(subject).to include('shard')
        expect(subject).to include('took_millis')
        expect(subject).to include('types')
        expect(subject).to include('search_type')
        expect(subject).to include('total_shards')
        expect(subject).to include('source')
        expect(subject).to include('source_id')
        unless event_get(subject, 'source_normalized') == source_normalized[i]
          puts event_get(subject, 'source_normalized')
        end
        expect(event_get(subject, 'source_normalized')).to eq(source_normalized[i])
      end
    end
  end

  invalid_messages = IO.read(File.join(File.dirname(__FILE__), 'fixture_invalid.txt')).split("\n")
  invalid_messages.each_with_index do |message, i|
    describe "fixtures_invalid #{i}" do
      sample('message' => message) do
        expect(subject).to include('message')
      end
    end
  end

  def event_get(event, field)
    if event.respond_to?(:get)
      event.get(field)
    else
      event[field]
    end
  end
end
