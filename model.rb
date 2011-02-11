DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/commandr.db")
#DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://#{Dir.pwd}/timup.db")

class Work
  include DataMapper::Resource

  property :id,         Serial,:key => true
  property :titre,      String
  property :body,       Text
  property :desc,       Text
  property :views,      Integer, :required=>false, :default=>0
  property :type,       Text
  property :created_at, EpochTime
  property :updated_at, EpochTime

  property :count_favorite,  Integer, :default=>0
  property :user_id,    Integer

  validates_presence_of :titre,:message=>'Le titre de la publication ne doit pas être vide'
  validates_uniqueness_of :titre,:message=>'Le titre de la publication existe déjà, soyez original un peu!'
  validates_presence_of :body,:message=>'Vous devez entrez un peu de code au moins!'
  validates_presence_of :desc,:message=>'La description de la publication ne doit pas être vide'


  has n, :comments
  has n, :favorites
  has n, :users, :through => :favorites, :unique => true

  belongs_to :user

end

class User

  include DataMapper::Resource

  property :id,         Serial, :key=>true
  property :username,   String
  property :password,   String
  property :created_at, EpochTime, :required=>false, :default=>(Time.now).to_i
  property :updated_at,  EpochTime, :required=>false, :default=>(Time.now).to_i
  has n, :works
  has n, :comments

  has n, :friendships, :child_key => [ :source_id ]
  has n, :friends, self, :through => :friendships, :via => :target
  
  has n,:favorites
  has n, :users, :through => :favorites, :unique => true

end

class Friendship
  include DataMapper::Resource
  
  property :source_id, Integer, :key => true, :min => 1
  property :target_id, Integer, :key => true, :min => 1

  belongs_to :source, 'User', :key => true
  belongs_to :target, 'User', :key => true

  def self.between source,target
    return first(:source=>source, :target=>target)
  end
end


class Favorite
  include DataMapper::Resource

  property :created_at, EpochTime, :required=>false, :default=>(Time.now).to_i

  belongs_to :user, :key=>true
  belongs_to :work, :key=>true

  def self.is_favorite user,work
    if first(:fields=>[:work_id],:user=> user, :work=>work)
      return "favori"
    else
      return nil
    end
  end

end



class Comment
  include DataMapper::Resource

  property :id,         Serial
  property :nom,        String
  property :body,       Text, :required=>true
  property :created_at, EpochTime, :required=>false, :default=>(Time.now).to_i
  property :created_at, EpochTime
  property :user_id,    Integer, :required=>false

  belongs_to :work
  belongs_to :user
end

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!
DataMapper.finalize

