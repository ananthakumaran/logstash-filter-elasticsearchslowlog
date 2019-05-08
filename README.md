# Elasticsearch Slowlog Logstash Plugin [![Build Status](https://travis-ci.org/ananthakumaran/logstash-filter-elasticsearchslowlog.svg?branch=master)](http://travis-ci.org/ananthakumaran/logstash-filter-elasticsearchslowlog)

## Installation

```
logstash-plugin install logstash-filter-elasticsearchslowlog
```

## Sample Configuration

```
filter {
  elasticsearchslowlog {
  }

  date {
    match => ["local_timestamp", "ISO8601"]
    timezone => "Asia/Jakarta"
  }
}
```

## What is it?

Given a slowlog source message like

```
[2017-09-10T12:35:53,355][WARN ][index.search.slowlog.fetch] [GOgO9TD]
[testindex-slowlogs][0] took[150.6micros], took_millis[0], types[],
stats[], search_type[QUERY_THEN_FETCH], total_shards[5],
source[{\"query\":{\"match\":{\"name\":{\"query\":\"Nariko\",\"operator\":\"OR\",\"prefix_length\":0,\"max_expansions\":50,\"fuzzy_transpositions\":true,\"lenient\":false,\"zero_terms_query\":\"NONE\",\"boost\":1.0}}},\"sort\":[{\"price\":{\"order\":\"desc\"}}]}]
```

the filter will parse and add the parsed fields to the event. In
addition, it will also add `source_normalized` field, which is same as
`source` except all the query params are replaced with `?`. This will
help with grouping same queries with different params. A md5 hash of
the normalized source is added as `source_id` field.

```
{
                 "node" => "GOgO9TD",
                "shard" => 0,
               "source" => "{\"query\":{\"match\":{\"name\":{\"query\":\"Nariko\",\"operator\":\"OR\",\"prefix_length\":0,\"max_expansions\":50,\"fuzzy_transpositions\":true,\"lenient\":false,\"zero_terms_query\":\"NONE\",\"boost\":1.0}}},\"sort\":[{\"price\":{\"order\":\"desc\"}}]}",
              "message" => "[2017-09-10T12:35:53,355][WARN ][index.search.slowlog.fetch] [GOgO9TD] [testindex-slowlogs][0] took[150.6micros], took_millis[0], types[], stats[], search_type[QUERY_THEN_FETCH], total_shards[5], source[{\"query\":{\"match\":{\"name\":{\"query\":\"Nariko\",\"operator\":\"OR\",\"prefix_length\":0,\"max_expansions\":50,\"fuzzy_transpositions\":true,\"lenient\":false,\"zero_terms_query\":\"NONE\",\"boost\":1.0}}},\"sort\":[{\"price\":{\"order\":\"desc\"}}]}]",
                 "took" => "150.6micros",
                "stats" => "",
                "level" => "WARN",
             "@version" => "1",
                "index" => "testindex-slowlogs",
      "local_timestamp" => "2017-09-10T12:35:53",
           "@timestamp" => 2017-09-10T05:35:53.000Z,
                 "host" => "Ananthas-MacBook-Pro.local",
         "total_shards" => 5,
    "source_normalized" => "{\"query\":{\"match\":{\"name\":{\"boost\":1.0,\"fuzzy_transpositions\":true,\"lenient\":false,\"max_expansions\":50,\"operator\":\"OR\",\"prefix_length\":0,\"query\":\"?\",\"zero_terms_query\":\"NONE\"}}},\"sort\":[{\"price\":{\"order\":\"desc\"}}]}",
            "source_id" => "289972b28",
                "types" => "",
          "search_type" => "QUERY_THEN_FETCH",
          "took_millis" => 0
}
```
