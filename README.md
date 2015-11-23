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

#sample source to read csv file
<source>
  type tail

  #path- where you placed your input data
  path ./input/Customer.csv

  # pos_file where you record file position
  pos_file ./log/customer.log.pos

  # for bigobject output plugin, use tag bigobject.${table_pattern}.${event}.${primary_key}
  # ${primary_key} is not needed for insert
  tag bigobject.cust.insert

  #input file format
  format csv

  # keys - columns in csv file
  keys id,name,language,state,company,gender,age

  #types - string/bool/integer/float/time/array
  types age1:integer

</source>

# Send data to BigObject using Restful API. Tables need to be created in advance in BigObject.
# depending on the event in tag received, will send data to BigObject for insert/update/delete. 
#
# Tag for each event - bigobject.${table_pattern}.${event}.${primary_key}.
# ${table_pattern} : will match to the <pattern> in <table> section of bigobject output plugin
# ${event} : valid event type by insert/update/delete.
# ${primary_key} : the primary key for table, optional for insert event.
# if primary_key is integer type in BigObject, set bo_primary_key_is_int to true 
#
# Eg:
# tag bigobject.cust.insert ==> INSERT INTO <table> VALUES ...
# tag bigobject.cust.delete.id ==> DELETE FROM <table> WHERE id=...
# tag bigobject.cust.update.id ==> UPDATE <table> SET ... WHERE id=...

<match bigobject.**>
  type bigobject

  log_level info

  # specify the bigobject host/port to connect to
  bigobject_hostname 192.168.59.103
  bigobject_port 9090

  remove_tag_prefix bigobject.
  flush_interval 60s

  <table>
      table Customer
      pattern cust

      #optional-
      #bo_primary_key_is_int true #defualts to false
      #column_mapping id,name,language,state,company,gender,age
      #bo_workspace
      #bo_opts
  </table>
</match>

```


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

