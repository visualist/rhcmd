module Command

  Available_commands = %w{help info config ls}.map(&:to_sym)

  def self.available_command subcmd
    Available_commands.include?(subcmd.to_sym)
  end

  def self.help args, options
    puts "No help, as of yet."
  end

  def self.info args, options
    puts "No info, as of yet."
  end

  def self.config args, options
    puts "Configuration for #{ENV['RHCMD_ENV']}:"
    Config.each_pair do |k,v|
      puts "  #{k} = #{v}"
    end
    puts "Args: #{args}"
    puts "Opts: #{options}"
  end

  def self.ls args, options
  end

end
