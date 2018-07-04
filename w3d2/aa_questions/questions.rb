require 'sqlite3'
require 'singleton'
require 'byebug'

class QuestionsDatabase < SQLite3::Database
  include Singleton
  
  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Question
  attr_accessor :id, :title, :body, :user_id
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map {|question| Question.new(question)}
  end
  
  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.id = ?
    SQL
    Question.new(question.pop)
  end
  
  def create
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id)
      INSERT INTO
        questions (title, body, user_id)
      VALUES
        (?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id, @id)
      UPDATE
        plays
      SET
        title = ?, body = ?, user_id = ?
      WHERE
        id = ?
    SQL
  end
  
  def self.find_by_user_id(user_id)
    question = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.user_id = ?
    SQL
    question.map {|question| Question.new(question)}
  end
  
  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end
  
  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end
  
  def author
    user = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?
    SQL
    User.new(user.pop)
    
    def likers
      QuestionLike.likers_for_question_id(id)
    end
    
    def num_likes
      QuestionLike.num_likes_for_question_id(id)
    end
    
  end
  
  def replies
    Reply.find_by_question_id(id)
  end
  
  def followers
    QuestionFollow.followers_for_question_id(id)
  end
end

class Reply
  attr_accessor :id, :question_id, :parent_id, :user_id, :body
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map {|reply| Reply.new(reply)}
  end
  
  def self.find_by_user_id(user_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.user_id = ?
    SQL
    reply.map {|reply| Reply.new(reply)}
  end
  
  def self.find_by_question_id(question_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.question_id = ?
    SQL
    reply.map {|reply| Reply.new(reply)}
  end
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
    @body = options['body']
  end
  
  def create
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body)
      INSERT INTO
        replies (question_id, parent_id, user_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body, @id)
      UPDATE
        replies
      SET
        question_id = ?, parent_id = ?, user_id = ?, body = ?
      WHERE
        id = ?
    SQL
  end
  
  def author
    user = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?
    SQL
    User.new(user.pop)
    
  end
  
  def question
    question = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.id = ?
    SQL
    Question.new(question.pop)
    
  end
  
  def parent_reply
    raise "#{self} doesn't have a parent" unless parent_id
    parent_reply = QuestionsDatabase.instance.execute(<<-SQL, parent_id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.id = ?
    SQL
    Reply.new(parent_reply.pop)
  end
  
  def child_replies
    child_replies = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        replies.parent_id = ?
    SQL
    if child_replies.empty?
      raise "#{self} doesn't have any children"
    else
      child_replies.map { |child| Reply.new(child) }
    end
  end
end

class User
  attr_accessor :id, :fname, :lname
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map {|user| User.new(user)}
  end
  
  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id = ?
    SQL
    User.new(user.pop)
  end
  
  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        users.fname = ? AND users.lname = ?
    SQL
    User.new(user.pop)
  end
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
  
  def average_karma
    average = QuestionsDatabase.instance.execute(<<-SQL,  id)
      SELECT
        count(question_likes.user_id), count(questions.user_id)
      FROM
        questions
      JOIN 
        question_likes ON questions.id = question_likes.question_id
      WHERE
        question_likes.user_id = ?
      
    SQL
    debugger
    average.pop.values.first
  end
  
  def authored_questions
    Question.find_by_user_id(id)
  end
  
  def authored_replies
    Reply.find_by_user_id(id)
  end
  
  def followed_questions
    QuestionLike.followed_questions_for_user_id(id)
  end
  
  def liked_questions
    QuestionLike.liked_questions_user_id(id)
  end
end

class QuestionFollow
  attr_accessor :id, :user_id, :question_id
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map {|question| QuestionFollow.new(question)}
  end
  
  def self.followers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      users.id, users.fname, users.lname
    FROM
      users
    JOIN
      question_follows ON users.id = question_follows.user_id
    WHERE 
      question_follows.question_id = ?
    SQL
    users.map {|user| User.new(user)}
  end
  
  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      questions.id, questions.body, questions.title, questions.user_id
    FROM
      questions
    JOIN
      question_follows ON questions.id = question_follows.question_id
    WHERE
      question_follows.user_id = ?
    SQL
    questions.map {|question| Question.new(question)}
  end
  
  def self.most_followed_questions(n)
    most_followed = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id, questions.body, questions.title, questions.user_id
      FROM
        questions
      JOIN
        question_follows ON questions.id = question_follows.question_id
      GROUP BY
        question_follows.question_id
      ORDER BY
        COUNT(question_follows.question_id) DESC
      LIMIT
        ?
      SQL
      most_followed.map { |question| Question.new(question) }
  end
  
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
  
  def create
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, user_id, question_id)
      INSERT INTO
        question_follows (user_id, question_id)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, user_id, question_id, id)
      UPDATE
        question_follows
      SET
        user_id = ?, question_id = ?
      WHERE
        id = ?
    SQL
  end
end

class QuestionLike
  attr_accessor :id, :user_id, :question_id
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map {|question| QuestionLike.new(question)}
  end
  
  def self.likers_for_question_id(question_id)
    users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, users.fname, users.lname
      FROM
        users
      JOIN
        question_likes ON users.id = question_likes.user_id
      WHERE
        question_likes.question_id = ?
    SQL
    users.map { |user| User.new(user)}
  end
  
  def self.liked_questions_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, questions.body, questions.title, questions.user_id
      FROM
        questions
      JOIN
        question_likes ON questions.id = question_likes.question_id
      WHERE
        question_likes.user_id = ?
    SQL
    questions.map { |question| Question.new(question)}
    
  end
  
  def self.num_likes_for_question_id(question_id)
    num_likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      count(*)
    FROM
      question_likes
    WHERE
      question_likes.question_id = ?
    
    SQL
    num_likes.pop.values.first
  end
  
  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.id, questions.body, questions.title, questions.user_id
      FROM
        questions
      JOIN
        question_likes ON questions.id = question_likes.question_id
      GROUP BY
        question_likes.question_id
      ORDER BY
        count(*) DESC
      LIMIT
        ?
    SQL
    questions.map { |question| Question.new(question) }
  end
  
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
  
  def create
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, user_id, question_id)
      INSERT INTO
        question_likes (user_id, question_id)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDatabase.instance.execute(<<-SQL, user_id, question_id, id)
      UPDATE
        question_likes
      SET
        user_id = ?, question_id = ?
      WHERE
        id = ?
    SQL
  end
end


