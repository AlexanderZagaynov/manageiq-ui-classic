module TreeNode
  class Node
    attr_reader :tree

    def initialize(object, parent_id, tree)
      @object = object
      @parent_id = parent_id
      @tree = tree
    end

    def text
      @object.name
    end

    def tooltip
      nil
    end

    def image
      @object.try(:decorate).try(:fileicon)
    end

    def icon
      @object.try(:decorate).try(:fonticon)
    end

    def icon_background
      nil
    end

    def klass
      nil
    end

    def selectable
      true
    end

    def checked
      nil
    end

    def color
      nil
    end

    def checkable
      true
    end

    def expanded
      false
    end

    def hide_checkbox
      nil
    end

    def key
      if @object.try(:id).nil?
        # FIXME: this makes problems in tests
        # to handle "Unassigned groups" node in automate buttons tree
        "-#{@object.name.split('|').last}"
      else
        base_class = @object.class.base_model.name # i.e. Vm or MiqTemplate
        base_class = "Datacenter" if base_class == "EmsFolder" && @object.kind_of?(::Datacenter)
        base_class = "ManageIQ::Providers::Foreman::ConfigurationManager" if @object.kind_of?(ManageIQ::Providers::Foreman::ConfigurationManager)
        base_class = "ManageIQ::Providers::AnsibleTower::AutomationManager" if @object.kind_of?(ManageIQ::Providers::AnsibleTower::AutomationManager)
        prefix = TreeBuilder.get_prefix_for_model(base_class)
        cid = @object.id
        "#{@tree.try(:options).try(:[], :full_ids) && @parent_id.present? ? "#{@parent_id}_" : ''}#{prefix}-#{cid}"
      end
    end

    def escape(string)
      return string if string.nil? || string.blank? || string.html_safe?
      ERB::Util.html_escape(string)
    end

    def to_h
      node = {
        :key            => key,
        :text           => escape(text),
        :tooltip        => escape(tooltip),
        :image          => image ? ActionController::Base.helpers.image_path(image) : nil,
        :icon           => icon,
        :iconBackground => icon_background,
        :iconColor      => color,
        :hideCheckbox   => hide_checkbox,
        :class          => [selectable ? nil : 'no-cursor'].push(klass).compact.join(' ').presence, # add no-cursor if not selectable
        :selectable     => selectable,
        :checkable      => checkable ? nil : false,
        :state          => {
          :checked  => checked,
          :expanded => expanded,
        }.compact
      }

      node.delete_if { |_, v| v.nil? }
    end

    class << self
      private

      def set_attribute(attribute, value = nil, &block)
        atvar = "@#{attribute}".to_sym

        define_method(attribute) do
          result = instance_variable_get(atvar)

          if result.nil?
            if block_given?
              args = [@object, @parent_id].take(block.arity.abs)
              result = instance_exec(*args, &block)
            else
              result = value
            end
            instance_variable_set(atvar, result)
          end

          result
        end

        equals_method(attribute)
      end

      def set_attributes(*attributes, &block)
        attributes.each do |attribute|
          define_method(attribute) do
            result = instance_variable_get("@#{attribute}".to_sym)

            if result.nil?
              results = instance_eval(&block)
              attributes.each_with_index do |local, index|
                instance_variable_set("@#{local}".to_sym, results[index])
                result = results[index] if local == attribute
              end
            end

            result
          end

          equals_method(attribute)
        end
      end

      def equals_method(attribute)
        define_method("#{attribute}=".to_sym) do |result|
          instance_variable_set("@#{attribute}".to_sym, result)
        end
      end
    end
  end
end
