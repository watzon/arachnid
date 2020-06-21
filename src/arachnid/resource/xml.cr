require "xml"

module Arachnid
  class Resource
    class XML < Resource
      @document : ::XML::Node

      delegate :==, :[], :[]=, :[]?, :attribute?, :attributes, :cdata, :children, :comment?, :content,
               :content=, :delete, :document, :document?, :element, :encoding, :errors, :first_element_child,
               :fragment?, :hash, :inner_text, :inspect, :name, :name=, :namespace, :namespace_scopes, :next,
               :next_element, :next_sibling, :object_id, :parent, :previous, :previous_element, :previous_sibling,
               :processing_instruction, :root, :text, :text=, :text, :to_s, :to_unsafe, :to_xml, :type, :unlink,
               :version, :xml?, :xpath, :xpath_bool, :xpath_float, :xpath_node, :xpath_nodes, :xpath_string,
               to: @document

      def initialize(uri, response)
        super(uri, response)
        @document = ::XML.parse(response.body)
      end
    end
  end
end
