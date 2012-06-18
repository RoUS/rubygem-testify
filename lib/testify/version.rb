require('rubygems')
require('time') unless (Time.now.respond_to?(:iso8601))
require('versionomy')

module Testify

  @version	= Versionomy.parse('0.2.0')
  VERSION	= @version.to_s.freeze

  class << self

    def version
      return Testify.instance_variable_get(:@version)
    end

    def update_file(instr)
      lines = File.readlines(__FILE__)
      vpos = lines.find_index { |l| l =~ %r!^\s*VERSION\s*=! }
      lhs = (lines[vpos-1].match(%r!^(\s*@version\s*=)!).captures[0])
      line_new = lhs << ' @version.' << instr
      lws = line_new.match(%r!^(\s*)!).captures[0]
      remark = "#{lws}# Following line added #{Time.now.iso8601}\n"
      lines.insert(vpos, remark, line_new)
      File.open(__FILE__, 'w') { |io| io.puts(lines) }
    end

    def bump(field)
      #
      # Trust this to raise an exception.
      #
      self.version.bump(field)
      return self.update_file("bump(#{field.to_sym.inspect})")
    end

    def method_missing(mname, *args)
      if (self.version.respond_to?(mname))
        return self.version.send(mname, *args)
      end
      mname_s = mname.to_s
      if (mname[-1,1] == '=')
        base_mname = mname_s.sub(%r![^_[:alnum:]]*$!, '').to_sym
        if (self.version.respond_to?(base_mname))
          mod = "change(#{base_mname.inspect} => #{args[0].inspect})"
          return self.update_file(mod)
        end
      end
      super
    end

  end

end
