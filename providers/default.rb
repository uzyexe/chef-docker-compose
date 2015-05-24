require 'yaml'

def whyrun_supported?
  true
end

# Create docker-compose resource actions.
[ :up, :start, :stop, :kill, :destroy, :run].each do |command|
  action command do
    if command == :destroy
      compose! :kill
      compose! :rm, '--force'

      update_environment_file(environment_file, {delete: true})
    else
      compose! command
    end

  end
end

# Get path of environment file, and create it if needed.
def environment_file
  @environment_file ||= begin
    if action == :run
      path = Dir::Tmpname.make_tmpname('/tmp/one-off-compose-run-', rand(9999))
      update_environment_file(path)
      oneoff_yaml_rewrite(path)

    else
      project = new_resource.project
      components = [ run_context.node['docker-compose']['config_directory'], '' ]
      components << "#{project}_" if project != 'default'
      path = ::File.join(*components) << new_resource.application
      update_environment_file(path) 
    end

    path
  end
  @environment_file
end

# Executes arbitary docker-compose command
def execute_compose(yaml_path, command, *args)
  cmd = ::Compose::Command.new(yaml_path, new_resource.project)
  cmd.execute(command, *args)
end

private

# Execute docker-compose for a specific action
def compose!(command, *args)
  args = args.dup
  services = Array(new_resource.service)

  # Docker-compose arguments are build-up due to invocation order as:
  # docker-compose [-p, -f] command level0_args [services] level1_args

  args += compose_args(command, 0)
  services.each {|sv| args << sv}
  args += compose_args(command, 1)
  composesh = execute_compose(environment_file, command, *(args.compact))

  # Processs output and converge messages
  msg = "Running one-off compose command for #{services.first} with args: " <<
        "`#{compose_args(command, 1).join(' ')}'"
  converge_by(msg) {} if command == :run

  # Bulk output for :run and converge messages for anything else
  while line = composesh.output.gets
    line = line.strip
    puts line if command == :run

    converge_by(line) {} if !line.empty?
  end

  if !composesh.status.success?
    msg = "#{new_resource} exited with exitcode #{composesh.status.exitstatus}"
    Chef::Log.error msg
    raise RuntimeError, "#{new_resource} #{command} failed"
  end

ensure
  ::File.unlink(environment_file) if command == :run
end

# Get docker-compose command arguments
def compose_args(command, level)
  args = []

  if level == 0
    case command
    when :up
      args << '-d'
      args << '--no-recreate' unless new_resource.recreate   

    when :run
      args << '--rm' if new_resource.run_opts[:remove]
      args << '--no-deps' if new_resource.run_opts[:no_deps]
    end

  # level1 is only used for run command
  elsif level == 1 && command == :run
    run_opts = new_resource.run_opts

    if !run_opts[:command]
      Chef::Log.error "#{new_resource.name} expects run_opts[:command]"
      raise ArgumentError, "no command for :run action given"

    elsif Array(new_resource.service).size != 1
      Chef::Log.error "#{new_resource.name} you must specify :service argument"
      raise ArgumentError, "compose service name is expected, " <<
                           "#{new_resource.service.class} passed"
    end

    args = Array(new_resource.run_opts[:command])
  end

  args
end

# Generate oneoff yaml content, with entrypoint redefined if needed.
def oneoff_yaml_rewrite(path)
  run_opts = new_resource.run_opts
  return if run_opts[:entrypoint].nil?

  data = YAML.load(::IO.read(path))
  data.each do |svc, hash|
    next unless svc == Array(new_resource.service).first
    data[svc]['entrypoint'] = run_opts[:entrypoint]
  end

  ::File.open(path, 'w+') { |f| f.write(data.to_yaml) }
end

# Write docker-compose project environment file into compose.d config directory.
def update_environment_file(path, opts={})
  source = new_resource.source.dup
  src_cookbook = new_resource.cookbook || new_resource.cookbook_name.to_s
  variables    = new_resource.variables

  inline_eval do
    if source.size == 1
      source = source.pop
      crmeth = source.end_with?('.erb') ? :template : :cookbook_file
    else
      crmeth = :remote_file
    end

    self.send(crmeth, path) do
      action(opts[:delete] ? :delete : :create)

      owner 'root'
      group 'root'
      mode  00644
      source source
      variables variables    if crmeth == :template
      cookbook  src_cookbook if crmeth != :remote_file
    end
  end
end

def inline_eval(updated_by_any=true, &block)
  inline_updated = false
  saved_run_context = @run_context
  @run_context = @run_context.dup
  @run_context.resource_collection = Chef::ResourceCollection.new
  instance_eval(&block)

  Chef::Runner.new(@run_context).converge
  if updated_by_any && @run_context.resource_collection.any?(&:updated?)
    inline_updated = true
  end

  @run_context = saved_run_context
  new_resource.updated_by_last_action(inline_updated)
end
