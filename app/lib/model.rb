DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/commandr.db")

class Work
  include DataMapper::Resource
  include Paperclip::Resource  

  property :id,         Serial,:key => true
  property :titre,      String, :length=>50
  property :body,       Text
  property :desc,       Text, :length=>250
  property :views,      Integer, :default=>0
  property :type,       Text
  property :created_at, DateTime
  property :updated_at, DateTime

  property :count_favorite,  Integer, :default=>0
  property :count_comments,  Integer, :default=>0
  property :user_id,    Integer

  has_attached_file :file,
                    :url => "/public/:attachment/:id/:style/:basename.:extension",
                    :path => "public/files/images/:basename.:extension",
                    :styles => {:original => "450>x700>"}


  ##VALIDATIONS WORK##
  validates_presence_of :titre,:message=>'Le titre de la publication ne doit pas être vide'
  validates_uniqueness_of :titre,:message=>'Le titre de la publication existe déjà, soyez original un peu!'
  validates_presence_of :body,:message=>'Vous devez entrez un peu de code au moins!'
  validates_presence_of :desc,:message=>'La description de la publication ne doit pas être vide'


  has n, :comments
  has n, :favorites
  has n, :users, :through => :favorites, :unique => true

  belongs_to :user

  after :save do |work|
    user=User.get(work.user.id)
    user.count_works+=1
    user.derniere_publication=Time.now
    user.save
  end

  after :destroy do |work|
    user=User.get(work.user.id)
    user.count_works-=1
    user.save
  end

  def make_paperclip_mash(file_hash,filename)
    mash = Mash.new
    mash['tempfile'] = file_hash[:tempfile]
    ext=file_hash[:filename].partition "."
    ext=ext[1]+ext[2]
    mash['filename'] = filename+ext
    mash['content_type'] = file_hash[:type]
    mash['size'] = file_hash[:tempfile].size
    mash
  end

  def distance_of_time_in_words(time)
    from_time=time.to_time
    to_time=Time.now
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round
    case distance_in_minutes
        when 0..1
            case distance_in_seconds
                when 0..5   then 'il y a 5 secondes'
                when 6..10  then 'il y a 10 secondes'
                when 11..20 then 'il y a 20 secondes'
                when 21..59 then 'il y a moins d\'une minute'
                else             'il y a une minute'
            end

            when 2..45           then "il y a #{distance_in_minutes} minutes"
            when 46..90          then 'il y a environ une heure'
            when 90..1440        then "il y a #{(distance_in_minutes / 60).round} heures"
            when 1441..2880      then 'hier'
            when 2881..525961    then Time.at(from_time).strftime("%e %b")
        else                      Time.at(from_time).strftime("%e/%m/%Y")
    end
  end


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
  property :desc,       Text
  property :created_at, DateTime
  property :updated_at, DateTime

  property :count_followers, Integer, :default=>0
  property :count_follows, Integer, :default=>0
  property :count_works, Integer, :default=>0
  property :derniere_publication, DateTime


  ##VALIDATIONS USER##
  validates_presence_of :prenom,:message=>"Vous devez entrer votre prénom"
  validates_presence_of :nom,:message=>"Vous devez entrer votre nom"
  validates_presence_of :username,:message=>"Vous devez entrer un nom d'utilisateur"
  validates_presence_of :password,:message=>"Vous devez entrer un mot de passe"
  validates_length_of :password, :min=>4, :message=>"Votre mot de passe doit avoir au moins 4 caractères"
  validates_uniqueness_of :username,:message=>"Ce nom d'utilisateur est déjà utilisé"
  validates_presence_of :desc,:message=>'Vous devez entrez au moins un petit mot pour vous décrire'


  has n, :works
  has n, :comments

  has n, :fellowships, :child_key => [ :source_id ]
  has n, :follows, self, :through => :fellowships, :via => :target
  has n, :followers, self, :through => :fellowships, :via => :source
  
  has n, :favorites
  has n, :users, :through => :favorites, :unique => true
  
  helpers do 
    def is_self user,session
      if user==session
        return "self"
      else
        return nil
      end
    end
  end



end

class Fellowship
  include DataMapper::Resource

  property :source_id, Integer, :key => true, :min => 1
  property :target_id, Integer, :key => true, :min => 1

  belongs_to :source, 'User', :key => true
  belongs_to :target, 'User', :key => true

  after :save do |relation|
    relation.source.count_follows+=1
    relation.target.count_followers+=1
    relation.source.save
    relation.target.save
  end
  after :destroy do |relation|
    relation.source.count_follows-=1
    relation.target.count_followers-=1
    relation.source.save
    relation.target.save
  end

end


class Favorite
  include DataMapper::Resource

  property :created_at, EpochTime, :default=>(Time.now).to_i

  belongs_to :user, :key=>true
  belongs_to :work, :key=>true
  
  helpers do
    def is_favorite user,work
      if self.first(:fields=>[:work_id],:user=> user, :work=>work)
        return "favori"
      else
        return nil
      end
    end
  end

end



class Comment
  include DataMapper::Resource

  property :id,         Serial
  property :nom,        String
  property :body,       Text
  property :created_at, DateTime
  property :user_id,    Integer
  
  ##VALIDATIONS COMMENTAIRE##
  validates_presence_of :body,:message=>"Vous devez entrer un commentaire"
 
  belongs_to :work
  belongs_to :user

  after :save do |comment|
    work=Work.get(comment.work_id)
    work.count_comments=work.count_comments+1
    work.save
  end
  def distance_of_time_in_words(time)
    from_time=time.to_time
    to_time=Time.now
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round
    case distance_in_minutes
        when 0..1
            case distance_in_seconds
                when 0..5   then 'il y a 5 secondes'
                when 6..10  then 'il y a 10 secondes'
                when 11..20 then 'il y a 20 secondes'
                when 21..59 then 'il y a moins d\'une minute'
                else             'il y a une minute'
            end

            when 2..45           then "il y a #{distance_in_minutes} minutes"
            when 46..90          then 'il y a environ une heure'
            when 90..1440        then "il y a #{(distance_in_minutes / 60).round} heures"
            when 1441..2880      then 'hier'
            when 2881..525961    then Time.at(from_time).strftime("%e %b")
        else                      Time.at(from_time).strftime("%e/%m/%Y")
    end
  end
end

#DataMapper.auto_migrate!
#DataMapper.auto_upgrade!
DataMapper.finalize

