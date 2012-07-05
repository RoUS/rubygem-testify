# -*- coding: utf-8 -*-
#--
#   Copyright © 2005 Ken Coar
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#++

require('rubygems')
require('ostruct')
require('parseconfig')
require('pathname')

require('lib/version')

require('ruby-debug')
Debugger.start

module Testify

  class Runtime < OpenStruct

    def to_hash
      return @table.dup
    end

  end

  def runtime
    return (@runtime ||= Runtime.new)
  end

  def runtime=(*args)
    #
    # @todo foolproof this
    #
    @runtime = Runtime.new(*args)
  end
  module_function(:runtime, :runtime=)

  def init_config(location, settings_p=nil)
    path = Pathname.new(location).realpath.to_s
    config_dir = File.join(path, '.testify')
    Dir.mkdir(config_dir) unless (File.directory?(config_dir))
    config_file = File.join(config_dir, 'config')
    unless (File.exist?(config_file))
      File.open(config_file, 'w') do |io|
        io.puts("VERSION = #{Testify::VERSION}")
      end
    end
    cfg = ParseConfig.new(config_file)
    unless (cfg['VERSION'])
      cfg.add('VERSION', Testify::VERSION)
      File.open(config_file, 'w') { |io| cfg.write(io) }
    end
    return cfg
  end
  protected(:init_config)
  module_function(:init_config)

  def init_global
    config = self.init_config(ENV['HOME'])
    unless (config.groups.include?('global'))
      config.add_to_group('global', '', '')
      File.open(config.config_file, 'w') { |io| config.write(io) }
    end
    return config
  end
  module_function(:init_global)

  def init_local
    config = self.init_config('.')
    unless (config.groups.include?('local'))
      config.add_to_group('local', '', '')
      File.open(config.config_file, 'w') { |io| config.write(io) }
    end
    return config
  end
  module_function(:init_local)

  def get_config
    merged_cfg = self.init_global.params.merge(self.init_local.params)
    pp(merged_cfg)
    return merged_cfg
  end
  module_function(:get_config)

end
