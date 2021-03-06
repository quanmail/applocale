require File.expand_path('../../setting.rb', __FILE__)
require File.expand_path('../../../Util/error_util.rb', __FILE__)
require File.expand_path('../../../Util/regex_util.rb', __FILE__)

module Applocale

  class ParseXMLFile
    attr_reader :strings_keys, :errorlist, :in_multiline_comments, :keys_list, :platform, :injectobj

    def initialize(platform, langpathobj_list, injectobj)
      @strings_keys = {}
      @keys_list = Array.new
      @errorlist = Array.new()
      @platform = platform
      @injectobj = injectobj
      self.to_parse_files(langpathobj_list)
    end

    def to_parse_files(langpathobj_list)
      langpathobj_list.each do |langpathobj|
        self.to_parse_strings_file(langpathobj.lang, langpathobj.filepath)
      end
    end

    def to_parse_strings_file(lang, strings_path)
      return if !File.exist? strings_path
      puts "Start to Parse xml file: \"#{strings_path}\" ...".green

      xml_doc = Nokogiri::XML(File.open(strings_path))
      string_nodes = xml_doc.xpath("//string")
      string_nodes.each do |node|
        key = node["name"]
        value = node.content
        if !key.nil? && key.strip.length > 0
          if @strings_keys[key].nil?
            @strings_keys[key] = Hash.new
            @keys_list.push(key)
          end
          if @strings_keys[key][lang.to_s].nil?
            @strings_keys[key][lang.to_s] = Hash.new
            @strings_keys[key][lang.to_s][:value] = self.remove_escape(lang, key, value)
          else
            error = ErrorUtil::ParseLocalizedError::DuplicateKey.new(key, -1, strings_path, lang, -1)
            @errorlist.push(error)
          end
        end
      end
    end

    def remove_escape(lang, key, content)
      value = content
      if @injectobj.has_before_parse_from_locale
        value = @injectobj.load_before_parse_from_locale(lang.to_s, key,  value)
      end
      if @injectobj.has_parse_from_locale
        value = @injectobj.load_parse_from_locale(lang.to_s, key,  value)
      else
        value = ContentUtil.remove_escape(@platform, value)
      end
      if @injectobj.has_after_parse_from_locale
        value = @injectobj.load_after_parse_from_locale(lang.to_s, key,  value)
      end
      return value
    end

  end
end
