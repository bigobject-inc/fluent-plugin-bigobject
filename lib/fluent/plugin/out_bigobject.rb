class Fluent::BigObjectOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('bigobject', self)
  
  include Fluent::SetTimeKeyMixin
  include Fluent::SetTagKeyMixin

  config_param :bigobject_url, :string
  config_param :remove_tag_prefix, :string, :default => nil
  config_param :send_unknown_chunks, :string,  :default=>true

  attr_accessor :tables
  
  unless method_defined?(:log)
    define_method(:log) { $log }
  end
  
  class TableElement
    include Fluent::Configurable

    config_param :table, :string
    config_param :column_mapping, :string
    config_param :pattern, :string, :default=>nil
    config_param :bo_workspace, :string, :default=>nil
    config_param :bo_opts, :string, :default=>nil

    attr_reader :mpattern

    def initialize(log)
      super()
      @log = log
    end

    def configure(conf)
      super
      @mpattern = Fluent::MatchPattern.create(pattern)
      @mapping = parse_column_mapping(@column_mapping)
      @log.info("column mapping for #{table} - #{@mapping}")
      @format_proc = Proc.new { |record|
        new_record = {}
        @mapping.each { |k, c|
          new_record[c] = record[k]
        }
        new_record
      }
    end

    def send(bourl, chunk)
      stmts = Array.new
      i=0
      columns = nil
      chunk.msgpack_each { |tag, time, data|
         keys = Array.new
         values = Array.new
         data = @format_proc.call(data)
         data.keys.sort.each do |key|
           keys << key
           values << data[key]
         end
         if columns.to_s.empty?
           columns = "(#{keys.join(",")})"
         end
         #single quote each column data
         stmts.push("('#{values.join("','")}')")
         i+=1
      }
      
      sendStmt = "INSERT INTO #{@table}  #{columns} VALUES" + stmts.join(",")
#      @log.debug("sendStmt=", sendStmt)
      @log.info("bigobject start insert #{i} rows")
      resp = sendBO(bourl, sendStmt)
      parsed = JSON.parse(resp)
      err = parsed['Err']
#      puts "Content=#{parsed['Content']}, Err=#{err}"
      if (err.to_s!='')
        @log.error("[BigObject] #{err}")
      end
      @log.info("bigobject end insert #{i} rows")
      
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
      @log.debug("\nbourl=#{bourl} params=#{params.to_json}")
    
      begin
        resp = RestClient.post bourl, params.to_json, :content_type =>:json, :accept =>:json
        @log.debug("resp= #{resp.body}")  
      rescue Exception => e 
        @log.error(e.message)  
        raise "Failed to sendBO: #{e.message}"
      end
      return resp
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

    @tables = []
    @default_table = nil
    conf.elements.select { |e|
      e.name == 'table'
    }.each { |e|
      te = TableElement.new(log)
      te.configure(e)
#      puts "conf.elements #{e}"
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
    log.info("bigobject shutdown")
  end 
  
  
  # This method is called when an event reaches to Fluentd.
  def format(tag, time, record)
#    puts "tag=#{tag}, time=#{time}, record=#{record}"
    [tag, time, record].to_msgpack
  end
  
  # This method is called every flush interval. Write the buffer chunk
  # to files or databases here. 
  # 'chunk' is a buffer chunk that includes multiple formatted events. 
  def write(chunk)
    unknownChunks = []
    @tables.each { |table|
#      puts "write table #{table}"
#      puts "chunk.key= #{chunk.key}"
      if table.mpattern.match(chunk.key)
        log.info("add known chunk #{chunk.key}")
        return table.send(@bigobject_url, chunk)
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