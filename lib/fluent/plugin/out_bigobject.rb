class Fluent::BigObjectOutput < Fluent::BufferedOutput

  Fluent::Plugin.register_output('bigobject', self)
  
  include Fluent::SetTimeKeyMixin
  include Fluent::SetTagKeyMixin

  config_param :bigobject_hostname, :string
  config_param :bigobject_port, :integer
  config_param :remove_tag_prefix, :string, :default => nil
#  config_param :send_unknown_chunks, :string,  :default=>true
  config_param :tag_format, :string, :default => nil
  
  DEFAULT_TAG_FORMAT = /(?<table_name>[^\.]+)\.(?<event>[^\.]+)\.(?<primary_key>[^\.]+)$/

  attr_accessor :tables
  
  unless method_defined?(:log)
    define_method(:log) { $log }
  end
  
  class TableElement
    include Fluent::Configurable

    config_param :table, :string
    config_param :column_mapping, :string, :default=>nil
    config_param :pattern, :string, :default=>nil
    config_param :bo_workspace, :string, :default=>nil
    config_param :bo_opts, :string, :default=>nil
    config_param :bo_primary_key_is_int, :bool, :default=>false

    attr_reader :mpattern

    def initialize(log, bo_hostname, bo_port, tag_format)
      super()
      @log = log
      @bo_hostname = bo_hostname
      @bo_port = bo_port
      @bo_url="http://#{@bo_hostname}:#{@bo_port}/cmd"
      @tag_format = tag_format
    end

    def configure(conf)
      super

      @mpattern = Fluent::MatchPattern.create(pattern)
      @mapping = (@column_mapping==nil)? nil:parse_column_mapping(@column_mapping)
      @log.info("column mapping for #{table} - #{@mapping}")
      @format_proc = Proc.new { |record|
        if (@mapping==nil)
          record
        else
          new_record = {}
          @mapping.each { |k, c|
            new_record[c] = record[k]
            }
          new_record
        end
      }
    end
    
    def getPkeyValue(value)
      if (@bo_primary_key_is_int)
           return value
      else
           return"\"#{value}\""
      end
    end
    
    

    #Send Data to Bigobject using Restful API
    def send(chunk)
      insertStmts = Array.new
      deleteStmts = Array.new
      
      columns = nil
      chunk.msgpack_each { |tag, time, data|
        
         tag_parts = tag.match(@tag_format)
         target_event = tag_parts['event']
         id_key = tag_parts['primary_key']
           
         keys = Array.new
         values = Array.new
         data = @format_proc.call(data)
         data.keys.sort.each do |key|
            keys << key
            values << data[key].to_json
         end
          
         if (target_event=='insert')
            if columns.to_s.empty?
              columns = "(#{keys.join(",")})"
            end
            insertStmts.push("(#{values.join(",")})")
         elsif (target_event=='update')
           pkey=""
           updates = Array.new
           keys.zip(values) { |key, value|
               if (key==id_key)
                 pkey = getPkeyValue(value)
               else
                 updates.push("#{key}=#{value}")
               end 
           }
           sendStmt = "update #{table} set #{updates.join(",")} where #{id_key}=#{pkey}"
           sendBO(@bo_url, sendStmt)   
         elsif (target_event=='delete')
           keys.zip(values) { |key, value|
                if (key==id_key)
                  pkey = getPkeyValue(value)
                end
                deleteStmts.push("#{id_key}=#{pkey}")
            }
         end
      }
      
      if insertStmts.length>0
        sendStmt = "INSERT INTO #{@table}  #{columns} VALUES" + insertStmts.join(",")
        sendBO(@bo_url, sendStmt)
        @log.debug("sending #{insertStmts.length} rows to bigobject for insert via Restful API")
      end 
      
      if deleteStmts.length>0
        sendStmt = "DELETE FROM #{@table} WHERE " + deleteStmts.join(" or ")
        sendBO(@bo_url, sendStmt)
        @log.debug("sending #{deleteStmts.length} rows to bigobject for delete via Restful API")
      end
    end
    
    def to_s
      "table:#{table}, column_mapping:#{column_mapping}, pattern:#{pattern}"
    end

    private
    def parse_column_mapping(column_mapping_conf)
      mapping = {}
      column_mapping_conf.split(',').each { |column_map|
        key, column = column_map.strip.split(':', 2)
        column = key if column.nil?
        mapping[key] = column
      }
      mapping
    end
    
    def formatRequest(stmt)
      params = Hash.new
      params['Stmt'] = stmt

      if @bo_workspace.to_s!=''
        params['Workspace'] = @bo_workspace
      end
      if @bo_opts.to_s!=''
        params['Opts'] = @bo_opts
      end
      return params
    end
    
    def sendBO(bourl, sendStmt)
      params = formatRequest(sendStmt)
      begin
        resp = RestClient.post bourl, params.to_json, :content_type =>:json, :accept =>:json
        @log.debug("resp= #{resp.body}")  
      rescue Exception => e 
        @log.error(e.message)  
        raise "Failed to sendBO: #{e.message}"
      end
      
      parsed = JSON.parse(resp)
      err = parsed['Err']
      if (err.to_s!='')
        @log.error("[BigObject] #{err}")
      end
      
    end
   
  end #end class
  
  def initialize
    super
    require 'rest-client'
    require 'json'
    log.info("bigobject initialize")
  end  
  
  def configure(conf)
    super
    
    if remove_tag_prefix = conf['remove_tag_prefix']
      @remove_tag_prefix = Regexp.new('^' + Regexp.escape(remove_tag_prefix))
    end

    if @tag_format.nil? || @tag_format == DEFAULT_TAG_FORMAT
      @tag_format = DEFAULT_TAG_FORMAT
    else
      @tag_format = Regexp.new(conf['tag_format'])
    end
    
    @tables = []
    @default_table = nil
 
    conf.elements.select { |e|
      e.name == 'table'
    }.each { |e|
      te = TableElement.new(log, @bigobject_hostname, @bigobject_port, @tag_format)
      te.configure(e)
      @tables << te
    }
    
#    @tables.each {|t| puts t.to_s}
  end
  
  def start
    super
    log.info("bigobject start")
  end
  
  def shutdown
    super
  end 

  # This method is called when an event reaches to Fluentd.
  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end
  
  # This method is called every flush interval. Write the buffer chunk
  # to files or databases here. 
  # 'chunk' is a buffer chunk that includes multiple formatted events. 
  def write(chunk)
    unknownChunks = []
    tag = chunk.key
    tag_parts = tag.match(@tag_format)
    target_table = tag_parts['table_name']
      
    @tables.each { |table|
      if table.mpattern.match(target_table)
        return table.send(chunk)
      end
    }
    
    log.warn("unknown chunk #{chunk.key}")
      
  end
  
  def format_tag(tag)
    if @remove_tag_prefix
      tag.gsub(@remove_tag_prefix, '')
    else
      tag
    end
  end
  
  def emit(tag, es, chain)
    super(tag, es, chain, format_tag(tag))
  end
end
