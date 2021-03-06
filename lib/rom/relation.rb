# encoding: utf-8

require 'rom/constants'

module ROM

  # Enhanced ROM relation wrapping axiom relation and using injected mapper to
  # load/dump tuples/objects
  #
  # @example
  #
  #   # set up an axiom relation
  #   header = [[:id, Integer], [:name, String]]
  #   data   = [[1, 'John'], [2, 'Jane']]
  #   axiom  = Axiom::Relation.new(header, data)
  #
  #   # provide a simple mapper
  #   class Mapper < Struct.new(:header)
  #     def load(tuple)
  #       data = header.map { |attribute|
  #         [attribute.name, tuple[attribute.name]]
  #       }
  #       Hash[data]
  #     end
  #
  #     def dump(hash)
  #       header.each_with_object([]) { |attribute, tuple|
  #         tuple << hash[attribute.name]
  #       }
  #     end
  #   end
  #
  #   # wrap axiom relation with ROM relation
  #   mapper   = Mapper.new(axiom.header)
  #   relation = ROM::Relation.new(axiom, mapper)
  #
  #   # relation is an enumerable and it uses mapper to load/dump tuples/objects
  #   relation.to_a
  #   # => [{:id=>1, :name=>'John'}, {:id=>2, :name=>'Jane'}]
  #
  #   # you can insert/update/delete objects
  #   relation.insert(id: 3, name: 'Piotr').to_a
  #   # => [{:id=>1, :name=>"John"}, {:id=>2, :name=>"Jane"}, {:id=>3, :name=>"Piotr"}]
  #
  #   relation.delete(id: 1, name: 'John').to_a
  #   # => [{:id=>2, :name=>"Jane"}]
  #
  class Relation
    include Enumerable
    include Equalizer.new(:mapper)
    include Charlatan.new(:relation, :kind => Axiom::Relation)

    attr_reader :mapper, :reader

    # Default relation reader object
    #
    # @api private
    class Reader

      # @api private
      def call(tuples, mapper)
        tuples.each { |tuple| yield(mapper.load(tuple)) }
      end

    end

    # @api public
    def self.new(relation, mapper, reader = Reader.new)
      super(relation, mapper, reader)
    end

    # @api private
    def initialize(relation, mapper, reader)
      super

      @mapper = mapper
      @reader = reader
    end

    # Iterate over tuples yielded by the wrapped relation
    #
    # @example
    #   mapper = Class.new {
    #     def load(value)
    #       value.to_s
    #     end
    #
    #     def dump(value)
    #       value.to_i
    #     end
    #   }.new
    #
    #   relation = ROM::Relation.new([1, 2, 3], mapper)
    #
    #   relation.each do |value|
    #     puts value # => '1'
    #   end
    #
    # @yieldparam [Object]
    #
    # @return [Relation]
    #
    # @api public
    def each(&block)
      return to_enum unless block_given?
      reader.call(relation.to_enum, mapper, &block)
      self
    end

    # Insert an object into relation
    #
    # @example
    #   axiom    = Axiom::Relation.new([[:id, Integer]], [[1], [2]])
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.insert(id: 3)
    #   relation.to_a # => [[1], [2], [3]]
    #
    # @param [Object]
    #
    # @return [Relation]
    #
    # @api public
    def insert(object)
      new(relation.insert([mapper.dump(object)]))
    end
    alias_method :<<, :insert

    # Update an object
    #
    # @example
    #   data     = [[1, 'John'], [2, 'Jane']]
    #   axiom    = Axiom::Relation.new([[:id, Integer], [:name, String]], data)
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.update({id: 2, name: 'Jane Doe'}, {id:2, name: 'Jane'})
    #   relation.to_a # => [[1, 'John'], [2, 'Jane Doe']]
    #
    # @param [Object]
    # @param [Hash] original attributes
    #
    # @return [Relation]
    #
    # @api public
    def update(object, original_tuple)
      new(relation.delete([original_tuple]).insert([mapper.dump(object)]))
    end

    # Delete an object from the relation
    #
    # @example
    #   axiom    = Axiom::Relation.new([[:id, Integer]], [[1], [2]])
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.delete(id: 1)
    #   relation.to_a # => [[2]]
    #
    # @param [Object]
    #
    # @return [Relation]
    #
    # @api public
    def delete(object)
      new(relation.delete([mapper.dump(object)]))
    end

    # Replace all objects in the relation with new ones
    #
    # @example
    #   axiom    = Axiom::Relation.new([[:id, Integer]], [[1], [2]])
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.replace([{id: 3}, {id: 4}])
    #   relation.to_a # => [[3], [4]]
    #
    # @param [Array<Object>]
    #
    # @return [Relation]
    #
    # @api public
    def replace(objects)
      new(relation.replace(objects.map(&mapper.method(:dump))))
    end

    # @api public
    def restrict(*args, &block)
      new(relation.restrict(*args, &block))
    end

    # @api public
    def sort_by(*args, &block)
      new(relation.sort_by(*args, &block))
    end

    # Take objects form the relation with provided limit
    #
    # @example
    #   axiom    = Axiom::Relation.new([[:id, Integer]], [[1], [2]])
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.take(2).to_a # => [[2]]
    #
    # @param [Integer] limit
    #
    # @return [Relation]
    #
    # @api public
    def take(limit)
      new(sorted.take(limit))
    end

    # Take first n-objects from the relation
    #
    # @example
    #   axiom    = Axiom::Relation.new([[:id, Integer]], [[1], [2]])
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.first.to_a # => [[1]]
    #   relation.first(2).to_a # => [[1], [2]]
    #
    # @param [Integer]
    #
    # @return [Relation]
    #
    # @api public
    def first(limit = 1)
      new(sorted.first(limit))
    end

    # Take last n-objects from the relation
    #
    # @example
    #   axiom    = Axiom::Relation.new([[:id, Integer]], [[1], [2]])
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.last.to_a # => [[2]]
    #   relation.last(2).to_a # => [[1], [2]]
    #
    # @param [Integer] limit
    #
    # @return [Relation]
    #
    # @api public
    def last(limit = 1)
      new(sorted.last(limit))
    end

    # Drop objects from the relation by the given offset
    #
    # @example
    #   axiom    = Axiom::Relation.new([[:id, Integer]], [[1], [2]])
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.drop(1).to_a # => [[2]]
    #
    # @param [Integer]
    #
    # @return [Relation]
    #
    # @api public
    def drop(offset)
      new(sorted.drop(offset))
    end

    # Return exactly one object matching criteria or raise an error
    #
    # @example
    #   axiom    = Axiom::Relation.new([[:id, Integer]], [1]])
    #   relation = ROM::Relation.new(axiom, mapper)
    #
    #   relation.one.to_a # => {id: 1}
    #
    # @param [Proc] block
    #   optional block to call in case no tuple is returned
    #
    # @return [Object]
    #
    # @raise NoTuplesError
    #   if no tuples were returned
    #
    # @raise ManyTuplesError
    #   if more than one tuple was returned
    #
    # @api public
    def one(&block)
      block  ||= ->() { raise NoTuplesError }
      tuples   = take(2).to_a

      if tuples.count > 1
        raise ManyTuplesError
      else
        tuples.first || block.call
      end
    end

    # @api private
    def inject_reader(new_reader)
      new(relation, mapper, new_reader)
    end

    # Join two relations
    #
    # @example
    #
    #   users.join(tasks)
    #
    # @return [Relation]
    #
    # @api public
    def join(other)
      new(relation.join(other.relation), mapper.join(other.mapper))
    end

    # Wrap one or more relation
    #
    # @example
    #
    #   tasks.join(users).wrap(user: tasks)
    #
    # @return [Relation]
    #
    # @api public
    def wrap(other)
      relation_wrap = other.each_with_object({}) { |(name, relation), o| o[name] = relation.header }
      mapper_wrap = other.each_with_object({}) { |(name, relation), o| o[name] = relation.mapper }

      new(relation.wrap(relation_wrap), mapper.wrap(mapper_wrap))
    end

    # Group one or more relation
    #
    # @example
    #
    #   users.join(tasks).group(tasks: tasks)
    #
    # @return [Relation]
    #
    # @api public
    def group(other)
      relation_group = other.each_with_object({}) { |(name, relation), o| o[name] = relation.header }
      mapper_group = other.each_with_object({}) { |(name, relation), o| o[name] = relation.mapper }

      new(relation.group(relation_group), mapper.group(mapper_group))
    end

    # Project a relation
    #
    # @example
    #
    #   users.project([:id, :name])
    #
    # @return [Relation]
    #
    # @api public
    def project(names)
      new(relation.project(names), mapper.project(names))
    end

    # Rename attributes in a relation
    #
    # @example
    #
    #   users.rename(:user_id => :id)
    #
    # @return [Relation]
    #
    # @api public
    def rename(names)
      new(relation.rename(names), mapper.rename(names))
    end

    # Sort wrapped relation using all attributes in the header
    #
    # @return [Axiom::Relation]
    #
    # @api private
    def sorted
      relation.sort
    end

    # Return new relation instance
    #
    # @return [Relation]
    #
    # @api private
    def new(new_relation, new_mapper = mapper, new_reader = reader)
      self.class.new(new_relation, new_mapper, new_reader)
    end

  end # class Relation

end # module ROM
