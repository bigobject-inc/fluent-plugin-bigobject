# Fluent::Plugin::Bigobject

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


<match bo.insert.*>
  type bigobject

  log_level info

  # specify the bigobject_url to connect to
  bigobject_url http://192.168.59.103:9090/cmd

  remove_tag_prefix bo.insert. 
  flush_interval 5s

  <table>
      table Customer
      column_mapping id,name,language,state,company,gender,age
      pattern customer
      #bo_workspace
      #bo_opts
  </table>

  <table>
    table search_test3
    # map to different column name in BigObject
    column_mapping 'ID:id3, TEXT:text3'
    pattern test3
  </table>

</match>


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andreasung/fluent-plugin-bigobject.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

