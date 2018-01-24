# fluent-plugin-claymore [![CircleCI](https://circleci.com/gh/timstott/fluent-plugin-claymore/tree/master.svg?style=svg)](https://circleci.com/gh/timstott/fluent-plugin-claymore/tree/master)

[Fluentd](https://fluentd.org/) parser plugin to extract metrics from Claymore
Dual Miner logs

## Requirements

| fluentd    | ruby   |
|------------|--------|
| >= v0.14.0 | >= 2.1 |

| Claymore Dual Miner | fluent-plugin-claymore |
|---------------------|------------------------|
| v10.0               | >= v1.0                |

## Installation

$ fluent-gem install fluent-plugin-claymore

## Usage

Use with any input plugins that have `parse` directive:

```
# fluentd.conf
<source>
  @type tail
  path *.txt
  read_from_head true
  tag claymore.data
  <parse>
    @type claymore
    # zero configuration 🎉
  </parse>
</source>

<match **>
  @type stdout
</match>
```

Demo configuration and sample data are available in [example](./example).
```console
cd example
fluentd -c fluentd.conf
```

A production configuration which uses InfluxDB to store time series may look like:

```
<source>
  @type tail
  path path/to/claymore/*_log.txt
  pos_file path/to/pos.pos
  refresh_interval 5
  tag claymore.data
  <parse>
    @type claymore
  </parse>
</source>

# re-tag events to use tag names as InfluxDB measurements
<match claymore.data>
  @type rewrite_tag_filter
  <rule>
    key type
    pattern GPU_HASH_RATE
    tag claymore.data.hash_rate
  </rule>
  <rule>
    key type
    pattern GPU_SHARE_FOUND
    tag claymore.data.share_found
  </rule>
  <rule>
    key type
    pattern GPU_TEMP
    tag claymore.data.temperature
  </rule>
</match>

<match claymore.data.*>
  @type copy

  <store>
    @type stdout
  </store>
  <store>
    @type influxdb
    host influxdb
    port 8086
    dbname claymore
    # uses fluentd tag when measurement not specified
    # measurement xxx
    time_precision ms
    auto_tags false
    tag_keys ["asset", "gpu", "hostname", "type"]
    sequence_tag _seq
    <buffer>
      flush_interval 1
    </buffer>
  </store>
</match>
```



## Events/Metrics

```json
[
  { "type": "GPU_HASH_RATE", "asset": "SC", "gpu": 1, "hash_rate": 300.583 },
  { "type": "GPU_SHARE_FOUND", "asset": "SC", "gpu": 1, "count": 1 },
  { "type": "TOTAL_HASH_RATE", "asset": "ETH", "hash_rate": 83.153 },
  { "type": "GPU_TEMP", "gpu": 1, "temperature": 47, "old_fan": 0, "new_fan": 75 },
  { "type": "CONNECTION_LOST", "asset": "SC", "count": 1 }
]
```

## Caveats

- The parser plugin only works with `input` plugins, not
  `filter` plugins. This is because `filter` plugins are unable to yield
  multiple results unlike `input`.

- The claymore logs timestamps is ignored since it excludes the date. Instead
  the timestamp when the line is read is used.
