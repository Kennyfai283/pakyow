# frozen_string_literal: true

require "pakyow/support/makeable"
require "pakyow/support/class_state"
require "pakyow/support/inflector"

require "pakyow/data/sources/abstract"

module Pakyow
  module Data
    module Sources
      # A relational data source through which you interact with a persistence
      # layer such as a sql database, redis, or http. Defines the schema, queries,
      # and other adapter-specific metadata (e.g. sql table).
      #
      # Each adapter provides its own interface for interacting with the underlying
      # persistence layer. For example, the sql adapter exposes +Sequel::Dataset+
      # provided by the *fantastic* Sequel gem.
      #
      # In normal use, the underlying dataset is inaccessible from outside of the
      # source. Instead, access to the dataset occurs through queries defined on
      # the source that interact with the dataset and return a result.
      #
      # Results are always returned as a new source instance (or when used from
      # the app, a {Pakyow::Data::Proxy} object). Access to the underlying value
      # is provided through methods such as +one+, +to_a+, and +each+.
      # (@see Pakyow::Data::Container#wrap_defined_queries!)
      #
      # Mutations occur through commands. Commands do not implement validation
      # other than checking for required attributes and checking that the given
      # attributes are defined on the source. Use the input verifier pattern to
      # verify and validate input before passing it to a command
      # (@see Pakyow::Verifier).
      #
      # @example
      #   source :posts, adapter: :sql, connection: :default do
      #     table :posts
      #
      #     primary_id
      #     timestamps
      #
      #     attribute :title, :string
      #
      #     command :create do |params|
      #       insert(params)
      #     end
      #
      #     def by_id(id)
      #       where(id: id)
      #     end
      #   end
      #
      #   data.posts.create(title: "foo")
      #   data.posts.by_id(1).first
      #   => #<Pakyow::Data::Object @values={:id => 1, :title => "foo", :created_at => "2018-11-30 10:55:05 -0800", :updated_at => "2018-11-30 10:55:05 -0800"}>
      #
      class Relational < Sources::Abstract
        require "pakyow/data/sources/relational/command"
        require "pakyow/data/sources/relational/migrator"

        # @api private
        attr_reader :container, :included

        def initialize(dataset, container:, object_map: {})
          __setobj__(dataset)
          @container, @object_map = container, object_map
          @wrap_as = self.class.singular_name
          @included = []

          if default_query = self.class.__default_query
            result = if default_query.is_a?(Proc)
              instance_exec(&default_query)
            else
              public_send(self.class.__default_query)
            end

            result = case result
            when self.class
              result.__getobj__
            else
              result
            end

            __setobj__(result)
          end
        end

        def all
          self
        end

        def including(association_name, &block)
          tap do
            association_name = association_name.to_sym

            association_to_include = self.class.associations.values.flatten.find { |association|
              association[:access_name] == association_name
            } || raise(UnknownAssociation.new("Unknown association `#{association_name}`").tap { |error| error.context = self.class })

            included_source = @container.source(association_to_include[:source_name])

            if association_to_include[:query_name]
              included_source = included_source.send(association_to_include[:query_name])
            end

            final_source = if block_given?
              included_source.instance_exec(&block) || included_source
            else
              included_source
            end

            @included << [association_to_include, final_source]
          end
        end

        def as(object)
          tap do
            @wrap_as = object
          end
        end

        def to_a
          return @results if instance_variable_defined?(:@results)
          @results = self.class.to_a(__getobj__)
          include_results!(@results)
          @results.map! { |result|
            finalize(result)
          }
        end

        def one
          return @results.first if instance_variable_defined?(:@results)
          return @result if instance_variable_defined?(:@result)

          if result = self.class.one(__getobj__)
            include_results!([result])
            @result = finalize(result)
          else
            nil
          end
        end

        def transaction(&block)
          @container.connection.transaction(&block)
        end

        def command(command_name)
          if command = self.class.commands[command_name]
            Command.new(
              command_name,
              block: command[:block],
              source: self,
              provides_dataset: command[:provides_dataset],
              performs_create: command[:performs_create],
              performs_update: command[:performs_update],
              performs_delete: command[:performs_delete]
            )
          else
            # TODO: raise a nicer error indicating what commands are available
            raise "unknown command #{command_name}"
          end
        end

        def count
          if self.class.respond_to?(:count)
            self.class.count(__getobj__)
          else
            super
          end
        end

        # @api private
        IVARS_TO_RELOAD = %i(
          @results @result
        )

        def reload
          IVARS_TO_RELOAD.select { |ivar|
            instance_variable_defined?(ivar)
          }.each do |ivar|
            remove_instance_variable(ivar)
          end

          self
        end

        def to_json(*)
          to_a.to_json
        end

        # @api private
        def source_name
          self.class.__object_name.name
        end

        # @api private
        def command?(maybe_command_name)
          self.class.commands.include?(maybe_command_name)
        end

        # @api private
        def query?(maybe_query_name)
          self.class.queries.include?(maybe_query_name)
        end

        # @api private
        MODIFIER_METHODS = %i(all as including).freeze
        # @api private
        def modifier?(maybe_modifier_name)
          MODIFIER_METHODS.include?(maybe_modifier_name)
        end

        # @api private
        NESTED_METHODS = %i(including).freeze
        # @api private
        def block_for_nested_source?(maybe_nested_name)
          NESTED_METHODS.include?(maybe_nested_name)
        end

        private

        def finalize(result)
          wrap(typecast(result))
        end

        def typecast(result)
          result.each do |key, value|
            unless value.nil? || !self.class.attributes.include?(key)
              result[key] = self.class.attributes[key][value]
            end
          end

          result
        end

        def wrap(result)
          wrapped_result = if @wrap_as.is_a?(Class)
            @wrap_as.new(result)
          else
            @object_map.fetch(@wrap_as, Object).new(result)
          end

          if wrapped_result.is_a?(Object)
            wrapped_result.originating_source = self.class
          end

          wrapped_result
        end

        def include_results!(results)
          @included.each do |association, combined_source|
            combined_source.__setobj__(
              combined_source.container.connection.adapter.result_for_attribute_value(
                association[:associated_column_name],
                results.map { |result| result[association[:column_name]] },
                combined_source
              )
            )

            combined_results = combined_source.to_a.group_by { |combined_result|
              combined_result[association[:associated_column_name]]
            }

            results.map! { |result|
              combined_results_for_result = combined_results[result[association[:column_name]]].to_a
              result[association[:access_name]] = if association[:access_type] == :one
                combined_results_for_result[0]
              else
                combined_results_for_result
              end

              result
            }
          end
        end

        extend Support::Makeable
        extend Support::ClassState

        class_state :__default_query
        class_state :timestamp_fields
        class_state :primary_key_field
        class_state :attributes, default: {}
        class_state :qualifications, default: {}, getter: false
        class_state :associations, default: { belongs_to: [], has_many: [], has_one: [] }
        class_state :commands, default: {}

        class << self
          attr_reader :name, :adapter, :connection

          def command(command_name, provides_dataset: true, performs_create: false, performs_update: false, performs_delete: false, &block)
            @commands[command_name] = {
              block: block,
              provides_dataset: provides_dataset,
              performs_create: performs_create,
              performs_update: performs_update,
              performs_delete: performs_delete
            }
          end

          def queries
            instance_methods - superclass.instance_methods
          end

          def query(query_name = nil, &block)
            @__default_query = query_name || block
          end

          def timestamps(create: :created_at, update: :updated_at)
            @timestamp_fields = {
              create: create,
              update: update
            }

            attribute create, :datetime
            attribute update, :datetime
          end

          def primary_id
            primary_key :id
            attribute :id, default_primary_key_type
          end

          def primary_key(field)
            @primary_key_field = field
          end

          def primary_key_type
            case primary_key_attribute
            when Hash
              primary_key_attribute[:type]
            else
              primary_key_attribute.meta[:mapping]
            end
          end

          def primary_key_attribute
            attributes[@primary_key_field]
          end

          def default_primary_key_type
            :integer
          end

          def attribute(name, type = :string, **options)
            attributes[name.to_sym] = {
              type: type,
              options: options
            }
          end

          def subscribe(query_name, qualifications)
            @qualifications[query_name] = qualifications
          end

          def qualifications(query_name)
            @qualifications.dig(query_name) || {}
          end

          def belongs_to(association_name, query: nil, source: association_name)
            access_name = Support.inflector.singularize(association_name)

            @associations[:belongs_to] << {
              type: :belongs_to,
              access_type: :one,
              access_name: access_name.to_sym,
              source_name: Support.inflector.pluralize(source).to_sym,
              query_name: query

              # The following values are set in Container#define_attributes_for_associations!
              #
              # column_name, column_type, associated_column_name
            }
          end

          # rubocop:disable Naming/PredicateName
          def has_many(association_name, query: nil, source: association_name, as: singular_name, dependent: :raise)
            @associations[:has_many] << {
              type: :has_many,
              access_type: :many,
              access_name: Support.inflector.pluralize(association_name).to_sym,
              source_name: Support.inflector.pluralize(source).to_sym,
              query_name: query,
              column_name: primary_key_field,
              column_type: primary_key_type,
              associated_access_name: as.to_sym,
              associated_column_name: :"#{as}_#{primary_key_field}",
              dependent: dependent
            }
          end
          # rubocop:enable Naming/PredicateName

          # rubocop:disable Naming/PredicateName
          def has_one(association_name, query: nil, source: association_name, as: singular_name, dependent: :raise)
            @associations[:has_one] << {
              type: :has_one,
              access_type: :one,
              access_name: Support.inflector.singularize(association_name).to_sym,
              source_name: Support.inflector.pluralize(source).to_sym,
              query_name: query,
              column_name: primary_key_field,
              column_type: primary_key_type,
              associated_access_name: as.to_sym,
              associated_column_name: :"#{as}_#{primary_key_field}",
              dependent: dependent
            }
          end
          # rubocop:enable Naming/PredicateName

          def make(name, adapter: Pakyow.config.data.default_adapter, connection: Pakyow.config.data.default_connection, state: nil, parent: nil, primary_id: true, timestamps: true, **kwargs, &block)
            super(name, state: state, parent: parent, adapter: adapter, connection: connection, attributes: {}, **kwargs) do
              adapter_class = Connection.adapter(adapter)
              if adapter_class.const_defined?("SourceExtension")
                # Extend the source with any adapter-specific behavior.
                #
                include(adapter_class.const_get("SourceExtension"))

                # Define default fields
                #
                self.primary_id if primary_id
                self.timestamps if timestamps
              end

              # Call the original block.
              #
              class_eval(&block) if block_given?
            end
          end

          # @api private
          def plural_name
            Support.inflector.pluralize(__object_name.name).to_sym
          end

          # @api private
          def singular_name
            Support.inflector.singularize(__object_name.name).to_sym
          end

          # @api private
          def source_from_source(*)
            super.tap(&:reload)
          end

          # @api private
          def find_association_to_source(source)
            associations.values.flatten.find { |association|
              association[:source_name] == source.class.plural_name ||
                association[:source_name] == source.class.singular_name
            }
          end
        end
      end
    end
  end
end
