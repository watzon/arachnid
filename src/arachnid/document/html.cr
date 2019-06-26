require "xml"

module Arachnid
  module Document
    struct HTML
      @content : String

      @document : XML::Node

      @ids : Hash(String, XML::Node)

      @tags : Hash(String, Array(Tag))

      @classes : Hash(String, Array(XML::Node))

      forward_missing_to @document

      def initialize(@content : String)
        @document = XML.parse_html(@content)

        @ids = {} of String => XML::Node
        @tags = {} of String => Array(Tag)
        @classes = {} of String => Array(XML::Node)

        visit @document
      end

      def self.parse(content : String)
        new(content)
      end

      # Transform the css query into an xpath query
      def self.css_query_to_xpath(query : String) : String
        query = "//#{query}"
        # Convert '#id_name' as '[@id="id_name"]'
        query = query.gsub /\#([A-z0-9]+-*_*)+/ { |m| "*[@id=\"%s\"]" % m.delete('#') }
        # Convert '.classname' as '[@class="classname"]'
        query = query.gsub /\.([A-z0-9]+-*_*)+/ { |m| "[@class=\"%s\"]" % m.delete('.') }
        # Convert ' > ' as '/'
        query = query.gsub /\s*>\s*/ { |m| "/" }
        # Convert ' ' as '//'
        query = query.gsub " ", "//"
        # a leading '*' when xpath does not include node name
        query = query.gsub /\/\[/ { |m| "/*[" }
        return query
      end

      # Find first tag by tag name and return
      # `HTML::Tag` if found or `nil` if not found
      def at_tag(tag_name : String) : Tag | Nil
        if tags = @tags[tag_name]?
          tags.each do |tag|
            return tag
          end
        end
        return nil
      end

      # Find all nodes by tag name and yield
      # `HTML::Tag` if found
      def where_tag(tag_name : String, &block) : Array(Tag)
        arr = [] of Tag
        if tags = @tags[tag_name]?
          tags.each do |tag|
            yield tag
            arr << tag
          end
        end
        return arr
      end

      # Find all nodes by classname and yield
      # `HTML::Tag` founded
      def where_class(class_name : String, &block) : Array(Tag)
        arr = [] of Tag
        if klasses = @classes[class_name]?
          klasses.each do |node|
            klass = Tag.new(node)
            yield klass
            arr << klass
          end
        end
        return arr
      end

      # Find a node by its id and return a
      # `HTML::Tag` found or `nil` if not found
      def at_id(id_name : String) : Tag | Nil
        if node = @ids[id_name]?
          return Tag.new(node)
        end
      end

      # Find all nodes corresponding to the css query and yield
      # `HTML::Tag` found or `nil` if not found
      def css(query : String) : Array(Tag)
        query = HTML.css_query_to_xpath(query)
        return @nodes.xpath_nodes("//#{query}").map { |node|
          tag = Tag.new(node)
          yield tag
          tag
        }
      end

      # Find first node corresponding to the css query and return
      # `HTML::Tag` if found or `nil` if not found
      def at_css(query : String)
        css(query) { |tag| return tag }
        return nil
      end

      private def add_id(id : String, node : XML::Node)
        @ids[id] = node
      end

      private def add_node(node : XML::Node)
        if @tags[node.name]? == nil
          @tags[node.name] = [] of Tag
        end
        @tags[node.name] << Tag.new(node)
      end

      private def add_class(klass : String, node : XML::Node)
        if @classes[klass]? == nil
          @classes[klass] = [] of XML::Node
        end
        @classes[klass] << node
      end

      # Depth-first visit. Given a node, extract metadata from
      # node (if exists), then visit each child.
      private def visit(node : XML::Node)
        # We only extract metadata from HTML nodes
        if node.element?
          add_node node
          if to = node["id"]?
            add_id to, node
          end
          if classes = node["class"]?
            classes.split(' ') { |to| add_class to, node }
          end
        end
        # visit each child
        node.children.each do |child|
          visit child
        end
      end

      # Represents an HTML Tag
      struct Tag
        getter node : XML::Node

        forward_missing_to @node

        def initialize(@node : XML::Node)
        end

        def classname : String | Nil
          return @node["class"]? ? @node["class"] : nil
        end

        def tagname : String
          return @node.name
        end

        def content : String
          return @node.text != nil ? @node.text.as(String) : "".as(String)
        end

        def parent : Tag | Nil
          if parent = @node.parent
            return Tag.new parent
          end
          nil
        end

        def children : Array(Tag)
          children = [] of Tag
          @node.children.each do |node|
            if node.element?
              children << Tag.new node
            end
          end
          children
        end

        def has_class?(klass : String) : Bool
          if classes = classname
            return classes.includes?(klass)
          end
          false
        end
      end
    end
  end
end
