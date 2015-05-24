module Compose
  class Command
    SUPPORTS = [
      :up, :start, :stop, :kill, :rm, :run, :ps, :logs
    ]
    attr_writer :binary
    attr_reader :shell

    def initialize(path, project=nil)
      @project   = project
      @path = path
    end

    def execute(command, *args)
      unless SUPPORTS.include? command
        raise ArgumentError, "unsupported compose command: #{command}"
      end

      @shell = ShellCommand.new command_line(command, *args)
      self
    end

    def status
      @shell.status
    end

    def output
      @shell.output
    end

    def binary
      @binary ||= 'docker-compose'
    end

    private

    def command_line(command, *args)
      s = Array(binary)
      s << "-f #{@path}"
      s << "-p #{@project}" if @project
      s << "#{command}"
      s + args
    end

  end
end
