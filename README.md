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
      #example of sending data to BigObject using binary avro
      pattern customer
      schema_file /fluentd/input/avsc/Customer.avsc
  </table>

</match>

<match bo.insert_rest.*>
  type bigobject

  log_level info 

  # specify the bigobject_url to connect to
  bigobject_hostname 192.168.59.103
  bigobject_port 9090

  remove_tag_prefix bo.insert_rest. 
  flush_interval 5s

  <table>
      table Customer
      #column_mapping id1:id,name,language,state,company,gender,age
      pattern customer
      #bo_workspace
      #bo_opts
  </table>
</match>
```


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

