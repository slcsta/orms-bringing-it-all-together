require "pry"
class Dog

    attr_accessor :id, :name, :breed

    def initialize(dog_attributes = {})
        dog_attributes.each do |key, value|
            self.send("#{key}=", value) if respond_to?("#{key}=")
        end
    end

    def self::create_table
        sql = <<-SQL
            CREATE TABLE IF NOT EXISTS dogs (
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            );
        SQL

        DB[:conn].execute(sql)
    end

    def self::drop_table
        sql = <<-SQL
            DROP TABLE IF EXISTS dogs
        SQL
        
        DB[:conn].execute(sql)
    end

    def save
        if self.id
            self.update
        else 
            sql = <<-SQL
            INSERT INTO dogs (name, breed) 
            VALUES (?, ?);
            SQL
        
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    # takes in a hash of attributes
    # uses metaprogramming to create a new dog object
    # then uses save method to save that dog to the database
    def self.create(dog_attributes)
        dog = Dog.new(dog_attributes)
        dog.save
        dog
    end

    # cast data into appropriate attributes of dog
    # create an instance with corresponding attribute values
    # return an array from db representing dog's data
    def self::new_from_db(row)
        new_dog = self.new
        new_dog.id = row[0]
        new_dog.name = row[1]
        new_dog.breed = row[2]
        new_dog
    end

    # returns a new dog object by id
    def self::find_by_id(id)
        sql = <<-SQL
            SELECT * 
            FROM dogs 
            WHERE id = ?
        SQL

        result = DB[:conn].execute(sql, id)[0]
        dog = Dog.new(id: result[0], name: result[1], breed: result[2])
        dog
    end


    def self::find_or_create_by(name:, breed:)
        sql = <<-SQL
            SELECT *
            FROM dogs
            WHERE name = ?
            AND breed = ?
        SQL

        dog = DB[:conn].execute(sql, name, breed)

        # if instance of dog does not already exist, create one
        # when two dogs have the same name and different breed, return correct dog
        
        if !dog.empty?
            dog_data = dog[0]
            dog = Dog.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
        else
            dog = self.create(name: name, breed: breed)
        end
        dog
    end

    
    def self::find_by_name(name)
        sql = <<-SQL
            SELECT *
            FROM dogs
            WHERE name = ?
        SQL
        
        result = DB[:conn].execute(sql, name)[0]
        dog = Dog.new(id: result[0], name: result[1], breed: result[2])
        dog
    end



    def update
        sql = <<-SQL
            UPDATE dogs 
            SET name = ?,
            breed = ?
            WHERE id = ?
        SQL

        DB[:conn].execute(sql, self.name, self.breed, self.id)
        self
    end
end

    