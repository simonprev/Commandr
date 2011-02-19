DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/commandr.db")
#DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://#{Dir.pwd}/timup.db")

class Work
  include DataMapper::Resource

  property :id,         Serial,:key => true
  property :titre,      String, :length=>50
  property :body,       Text
  property :desc,       Text, :length=>250
  property :views,      Integer, :default=>0
  property :type,       Text
  property :created_at, DateTime
  property :updated_at, DateTime

  property :count_favorite,  Integer, :default=>0
  property :user_id,    Integer

  ##VALIDATIONS WORK##
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
  property :nom,        String
  property :prenom,     String
  property :username,   String, :length=>50
  property :password,   String
  property :site_web,   String
  property :twitter_username, String
  property :desc,       String
  property :created_at, DateTime
  property :updated_at, DateTime
 

  ##VALIDATIONS USER##
  validates_presence_of :prenom,:message=>"Vous devez entrer votre prénom"
  validates_presence_of :nom,:message=>"Vous devez entrer votre nom"
  validates_presence_of :username,:message=>"Vous devez entrer un nom d'utilisateur"
  validates_uniqueness_of :username,:message=>"Ce nom d'utilisateur est déjà utilisé"
  validates_presence_of :desc,:message=>'Vous devez entrez au moins un petit mot pour vous décrire'


  has n, :works
  has n, :comments

  has n, :fellowships, :child_key => [ :source_id ]
  has n, :follows, self, :through => :fellowships, :via => :target
  has n, :followers, self, :through => :fellowships, :via => :source
  
  has n,:favorites
  has n, :users, :through => :favorites, :unique => true

end

class Fellowship
  include DataMapper::Resource
  
  property :source_id, Integer, :key => true, :min => 1
  property :target_id, Integer, :key => true, :min => 1

  belongs_to :source, 'User', :key => true
  belongs_to :target, 'User', :key => true

end


class Favorite
  include DataMapper::Resource

  property :created_at, EpochTime, :default=>(Time.now).to_i

  belongs_to :user, :key=>true
  belongs_to :work, :key=>true

end



class Comment
  include DataMapper::Resource

  property :id,         Serial
  property :nom,        String
  property :body,       Text
  property :created_at, DateTime
  property :user_id,    Integer
  
  ##VALIDATIONS USER##
  validates_presence_of :body,:message=>"Vous devez entrer un commentaire"
 
  belongs_to :work
  belongs_to :user
end

#DataMapper.auto_migrate!
#DataMapper.auto_upgrade!
DataMapper.finalize

