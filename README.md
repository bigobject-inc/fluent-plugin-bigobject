# fluent-plugin-bigobject

Fluentd output plugin for inserting data to BigObject

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-bigobject'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-bigobject

## Usage

Configure BigObject URL and the table/column to be mapped in BigObject

```apache
<match bo.insert.*>
  type bigobject

  log_level info

  # specify the bigobject to connect to
  bigobject_hostname 192.168.59.103
  bigobject_port 9091

  remove_tag_prefix bo.insert. 
  flush_interval 5s

  <table>
      table Customer
      pattern customer

      # optional - use for binary avro.
      #if omit schema_file, will use Restful API to connect to BigObject
      schema_file /fluentd/input/avsc/Customer.avsc
      
      #optional - not use in binary avro
      #bo_workspace

      #optional - not use in binary avro
      #bo_opts
  </table>

  <table>
    table search_test3
    # map to different column name in BigObject
    column_mapping 'ID:id3, TEXT:text3'
    pattern test3
  </table>

</match>
```


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

