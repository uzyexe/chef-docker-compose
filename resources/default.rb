require 'uri'
actions :up, :start, :stop, :kill, :destroy, :run
default_action :up

attribute :application,  :kind_of => String, :name_attribute => true
attribute :cookbook,     :kind_of => String
attribute :project,      :kind_of => String, :default => 'default'
attribute :recreate,     :kind_of => [TrueClass, FalseClass], :default => false
attribute :variables,    :kind_of => Hash,   :default => {}
attribute :service,      :kind_of => [Array, String]

def source(*args)
  if not args.empty?
    args = Array(args).flatten
    validate_source(args)
    @source = args
  elsif self.instance_variable_defined?(:@source) == true
    @source
  end
end

def run_opts(hash=nil)
  def_opts  ||= {remove: true, no_deps: true}
  @run_opts ||= def_opts

  if hash
    @run_opts = def_opts.merge(hash)
  else
    @run_opts
  end
end

private

def validate_source(source)
  raise ArgumentError, "#{resource_name} has an empty source" if source.empty?
  if source.size > 1
    source.each do |src|
      unless absolute_uri?(src)
        raise Exceptions::InvalidRemoteFileURI,
          "#{src.inspect} is not a valid `source` parameter for #{resource_name}. `source` must be an absolute URI or an array of URIs."
      end
    end
  end
end

def absolute_uri?(source)
  source.kind_of?(String) and URI.parse(source).absolute?
rescue URI::InvalidURIError
  false
end