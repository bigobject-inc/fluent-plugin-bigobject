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

# send data to BigObject using avro by providing schema_file in each table
<match bo.insert_avro.*>
  type bigobject

  log_level info

  # specify the bigobject host/port to connect to
  bigobject_hostname 192.168.59.103
  bigobject_port 9091

  remove_tag_prefix bo.insert_avro.
  flush_interval 60s

  <table>
      pattern customer
      schema_file /fluentd/input/avsc/Customer_binary.avsc
  </table>
</match>

# send data to BigObject using Restful API. Tables need to be created in advance in BigObject.
<match bo.insert_rest.*>
  type bigobject

  log_level info

  # specify the bigobject host/port to connect to
  bigobject_hostname 192.168.59.103
  bigobject_port 9090

  remove_tag_prefix bo.insert_rest.
  flush_interval 60s

  <table>
      table Customer
      pattern customer

      #optional-
      #column_mapping id,name,language,state,company,gender,age
      #bo_workspace
      #bo_opts
  </table>
</match>

```


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

